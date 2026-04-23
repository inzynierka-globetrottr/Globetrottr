package sniezynki.agh.globetrottr;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import sniezynki.agh.globetrottr.user.UserRepository;
import sniezynki.agh.globetrottr.user.dto.AuthRequest;
import sniezynki.agh.globetrottr.user.dto.AuthResponse;
import sniezynki.agh.globetrottr.user.dto.RegisterRequest;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@Testcontainers
@ActiveProfiles("test")
@AutoConfigureMockMvc
class AuthIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    @BeforeEach
    void cleanUp() {
        userRepository.deleteAll();
    }

    @Test
    void fullAuthFlowTest() throws Exception {
        // given
        RegisterRequest registerRequest = RegisterRequest.builder()
                .username("testuser")
                .email("test@globetrottr.com")
                .password("StrongPass123")
                .build();

        // when & then
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists());

        AuthRequest loginRequest = AuthRequest.builder()
                .login("testuser")
                .password("StrongPass123")
                .build();

        MvcResult loginResult = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        String responseBody = loginResult.getResponse().getContentAsString();
        AuthResponse authResponse = objectMapper.readValue(responseBody, AuthResponse.class);
        String token = authResponse.token();

        mockMvc.perform(get("/api/test/protected")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk());
    }

    @Test
    void shouldNotRegisterUserWithExistingEmail() throws Exception {
        // given
        RegisterRequest first = RegisterRequest.builder()
                .username("user1")
                .email("same@email.com")
                .password("pass1")
                .build();

        userRepository.save(sniezynki.agh.globetrottr.user.User.builder()
                .username(first.username())
                .email(first.email())
                .passwordHash("hashed")
                .build());

        RegisterRequest duplicate = RegisterRequest.builder()
                .username("user2")
                .email("same@email.com")
                .password("pass2")
                .build();

        // when & then
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(duplicate)))
                .andExpect(status().isConflict());
    }

    @Test
    void shouldNotLoginWithNonExistentUser() throws Exception {
        // given
        AuthRequest loginRequest = AuthRequest.builder()
                .login("ghost_user")
                .password("password")
                .build();

        // when & then
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldNotLoginWithWrongPassword() throws Exception {
        // given
        RegisterRequest reg = RegisterRequest.builder()
                .username("tester")
                .email("tester@test.com")
                .password("correct_pass")
                .build();

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(reg)));

        AuthRequest badLogin = AuthRequest.builder()
                .login("tester")
                .password("wrong_pass")
                .build();

        // when & then
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(badLogin)))
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldRejectRequestWithoutToken() throws Exception {
        // when & then
        mockMvc.perform(get("/api/test/protected"))
                .andExpect(status().isForbidden());
    }
}