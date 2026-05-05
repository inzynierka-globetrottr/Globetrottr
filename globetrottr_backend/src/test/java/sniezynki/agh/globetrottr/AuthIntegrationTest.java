package sniezynki.agh.globetrottr;

import org.hamcrest.Matchers;
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
        RegisterRequest registerRequest = RegisterRequest.builder()
                .username("testuser")
                .email("test@globetrottr.com")
                .password("StrongPass123!")
                .build();

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists());

        AuthRequest loginRequest = AuthRequest.builder()
                .login("testuser")
                .password("StrongPass123!")
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
        RegisterRequest first = RegisterRequest.builder()
                .username("user1")
                .email("same@email.com")
                .password("Pass123!@#")
                .build();

        userRepository.save(sniezynki.agh.globetrottr.user.User.builder()
                .username(first.username())
                .email(first.email())
                .passwordHash("hashed")
                .build());

        RegisterRequest duplicate = RegisterRequest.builder()
                .username("user2")
                .email("same@email.com")
                .password("Pass123!@#")
                .build();

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(duplicate)))
                .andExpect(status().isConflict());
    }

    @Test
    void shouldNotLoginWithNonExistentUser() throws Exception {
        AuthRequest loginRequest = AuthRequest.builder()
                .login("ghost_user")
                .password("StrongPass123!")
                .build();

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldNotLoginWithWrongPassword() throws Exception {
        RegisterRequest reg = RegisterRequest.builder()
                .username("tester")
                .email("tester@test.com")
                .password("CorrectPass123!")
                .build();

        mockMvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(reg)));

        AuthRequest badLogin = AuthRequest.builder()
                .login("tester")
                .password("WrongPass123!")
                .build();

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(badLogin)))
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldRejectRequestWithoutToken() throws Exception {
        mockMvc.perform(get("/api/test/protected"))
                .andExpect(status().isForbidden());
    }

    @Test
    void shouldRejectRegistrationWithWeakPasswordNoSpecialChar() throws Exception {
        RegisterRequest invalidRequest = RegisterRequest.builder()
                .username("tester1")
                .email("test1@globetrottr.com")
                .password("WeakPass123")
                .build();

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldRejectRegistrationWithWeakPasswordNoDigit() throws Exception {
        RegisterRequest invalidRequest = RegisterRequest.builder()
                .username("tester2")
                .email("test2@globetrottr.com")
                .password("WeakPass!!")
                .build();

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldRejectRegistrationWithWeakPasswordNoUppercase() throws Exception {
        RegisterRequest invalidRequest = RegisterRequest.builder()
                .username("tester3")
                .email("test3@globetrottr.com")
                .password("weakpass123!")
                .build();

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldRejectRegistrationWithInvalidEmail() throws Exception {
        RegisterRequest invalidRequest = RegisterRequest.builder()
                .username("tester4")
                .email("invalid-email")
                .password("StrongPass123!")
                .build();

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldRejectRegistrationWithEmptyUsername() throws Exception {
        RegisterRequest invalidRequest = RegisterRequest.builder()
                .username("")
                .email("test5@globetrottr.com")
                .password("StrongPass123!")
                .build();

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalidRequest)))
                .andExpect(status().isBadRequest());
    }

    @Test
    void shouldRefreshTokenSuccessfully() throws Exception {
        RegisterRequest registerRequest = RegisterRequest.builder()
                .username("refresher")
                .email("refresh@test.com")
                .password("StrongPass123!")
                .build();

        MvcResult registerResult = mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(registerRequest)))
                .andExpect(status().isOk())
                .andReturn();

        String responseBody = registerResult.getResponse().getContentAsString();
        AuthResponse authResponse = objectMapper.readValue(responseBody, AuthResponse.class);
        String oldToken = authResponse.token();

        Thread.sleep(1000);

        mockMvc.perform(get("/api/auth/refresh")
                        .header("Authorization", "Bearer " + oldToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").exists())
                .andExpect(jsonPath("$.token").value(Matchers.not(oldToken)));
    }

    @Test
    void shouldRejectRefreshWithoutToken() throws Exception {
        mockMvc.perform(get("/api/auth/refresh"))
                .andExpect(status().isBadRequest());
    }
}