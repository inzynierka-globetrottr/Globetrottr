package sniezynki.agh.globetrottr.friend;

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
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import sniezynki.agh.globetrottr.friend.dto.FriendshipRequest;
import sniezynki.agh.globetrottr.security.JwtService;
import sniezynki.agh.globetrottr.user.User;
import sniezynki.agh.globetrottr.user.UserRepository;
import sniezynki.agh.globetrottr.user.UserRole;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.hamcrest.Matchers.*;

@SpringBootTest
@Testcontainers
@ActiveProfiles("test")
@AutoConfigureMockMvc
class FriendshipIntegrationTest {

    @Container
    @ServiceConnection
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private FriendshipRepository friendshipRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtService jwtService;

    private final ObjectMapper objectMapper = new ObjectMapper().registerModule(new JavaTimeModule());

    private String tokenA;
    private String tokenB;
    private String tokenC;

    @BeforeEach
    void setUp() {
        friendshipRepository.deleteAll();
        userRepository.deleteAll();

        User userA = createUser("userA", "usera@example.com");
        User userB = createUser("userB", "userb@example.com");
        User userC = createUser("userC", "userc@example.com");
        
        tokenA = jwtService.generateToken(userA);
        tokenB = jwtService.generateToken(userB);
        tokenC = jwtService.generateToken(userC);
    }
    
    private User createUser(String username, String email) {
        User user = User.builder()
                .username(username)
                .email(email)
                .passwordHash("password")
                .role(UserRole.USER)
                .build();
        return userRepository.save(user);
    }

    @Test
    void testSendInviteAndAccept() throws Exception {
        // User A sends invite to User B
        FriendshipRequest request = new FriendshipRequest("userB");
        
        mockMvc.perform(post("/api/friends/invites")
                        .header("Authorization", "Bearer " + tokenA)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());

        // Check that B has pending invite from A
        mockMvc.perform(get("/api/friends/invites")
                        .header("Authorization", "Bearer " + tokenB))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].username").value("userA"))
                .andExpect(jsonPath("$[0].status").value("PENDING"))
                .andExpect(jsonPath("$[0].isIncomingRequest").value(true));
                
        // Check that A has sent invite to B
        mockMvc.perform(get("/api/friends/invites/sent")
                        .header("Authorization", "Bearer " + tokenA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].username").value("userB"))
                .andExpect(jsonPath("$[0].status").value("PENDING"))
                .andExpect(jsonPath("$[0].isIncomingRequest").value(false));

        // User B accepts invite
        mockMvc.perform(post("/api/friends/invites/userA/accept")
                        .header("Authorization", "Bearer " + tokenB))
                .andExpect(status().isOk());

        // Check that they are friends
        mockMvc.perform(get("/api/friends")
                        .header("Authorization", "Bearer " + tokenA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].username").value("userB"))
                .andExpect(jsonPath("$[0].status").value("ACCEPTED"));
    }

    @Test
    void testBlockUserAndHideStatus() throws Exception {
        // A blocks B
        mockMvc.perform(post("/api/friends/userB/block")
                        .header("Authorization", "Bearer " + tokenA))
                .andExpect(status().isOk());

        // B tries to check status with A, should see no status (null)
        mockMvc.perform(get("/api/friends/userA/status")
                        .header("Authorization", "Bearer " + tokenB))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.username").value("userA"))
                .andExpect(jsonPath("$.status").doesNotExist());
                
        // A searches for B, should not see B due to block
        mockMvc.perform(get("/api/friends/search")
                        .param("query", "userB")
                        .header("Authorization", "Bearer " + tokenA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
                
        // B searches for A, should see A but with no relationship status
        mockMvc.perform(get("/api/friends/search")
                        .param("query", "userA")
                        .header("Authorization", "Bearer " + tokenB))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].username").value("userA"))
                .andExpect(jsonPath("$[0].status").doesNotExist());
    }

    @Test
    void testRejectInviteOrDeleteFriend() throws Exception {
        // A sends invite to C
        FriendshipRequest request = new FriendshipRequest("userC");
        mockMvc.perform(post("/api/friends/invites")
                        .header("Authorization", "Bearer " + tokenA)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk());
                
        // C rejects invite
        mockMvc.perform(delete("/api/friends/userA")
                        .header("Authorization", "Bearer " + tokenC))
                .andExpect(status().isOk());
                
        // Check A has no sent invites
        mockMvc.perform(get("/api/friends/invites/sent")
                        .header("Authorization", "Bearer " + tokenA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }
}