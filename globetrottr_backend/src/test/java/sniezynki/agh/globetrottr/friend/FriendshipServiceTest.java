package sniezynki.agh.globetrottr.friend;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import sniezynki.agh.globetrottr.friend.dto.FriendshipResponse;
import sniezynki.agh.globetrottr.user.User;
import sniezynki.agh.globetrottr.user.UserRepository;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class FriendshipServiceTest {

    @Mock
    private FriendshipRepository friendshipRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private FriendshipService friendshipService;

    private User userA;
    private User userB;

    @BeforeEach
    void setUp() {
        userA = new User();
        userA.setUsername("userA");
        
        userB = new User();
        userB.setUsername("userB");
    }

    @Test
    void testSendInvite_Success() {
        when(userRepository.findByUsername("userA")).thenReturn(Optional.of(userA));
        when(userRepository.findByUsername("userB")).thenReturn(Optional.of(userB));
        when(friendshipRepository.findFriendshipBetween("userA", "userB")).thenReturn(Optional.empty());

        friendshipService.sendInvite("userA", "userB");

        verify(friendshipRepository, times(1)).save(any(Friendship.class));
    }

    @Test
    void testSendInvite_CannotInviteSelf() {
        assertThrows(IllegalArgumentException.class, () -> friendshipService.sendInvite("userA", "userA"));
    }

    @Test
    void testSendInvite_AlreadyFriends() {
        Friendship friendship = Friendship.builder().status(InviteStatus.ACCEPTED).build();
        when(friendshipRepository.findFriendshipBetween("userA", "userB")).thenReturn(Optional.of(friendship));

        assertThrows(RuntimeException.class, () -> friendshipService.sendInvite("userA", "userB"));
    }

    @Test
    void testSendInvite_BlockedBySender() {
        Friendship friendship = Friendship.builder().sender(userA).receiver(userB).status(InviteStatus.BLOCKED).build();
        when(friendshipRepository.findFriendshipBetween("userA", "userB")).thenReturn(Optional.of(friendship));

        RuntimeException exception = assertThrows(RuntimeException.class, () -> friendshipService.sendInvite("userA", "userB"));
        assertEquals("You must unblock this user before sending an invitation", exception.getMessage());
    }
    
    @Test
    void testSendInvite_BlockedByReceiver() {
        Friendship friendship = Friendship.builder().sender(userB).receiver(userA).status(InviteStatus.BLOCKED).build();
        when(friendshipRepository.findFriendshipBetween("userA", "userB")).thenReturn(Optional.of(friendship));

        RuntimeException exception = assertThrows(RuntimeException.class, () -> friendshipService.sendInvite("userA", "userB"));
        assertEquals("Cannot send invitation to this user", exception.getMessage());
    }

    @Test
    void testAcceptInvite_Success() {
        Friendship friendship = Friendship.builder().sender(userA).receiver(userB).status(InviteStatus.PENDING).build();
        when(friendshipRepository.findBySenderUsernameAndReceiverUsername("userA", "userB")).thenReturn(Optional.of(friendship));

        friendshipService.acceptInvite("userB", "userA");

        assertEquals(InviteStatus.ACCEPTED, friendship.getStatus());
        verify(friendshipRepository, times(1)).save(friendship);
    }
    
    @Test
    void testAcceptInvite_NotPending() {
        Friendship friendship = Friendship.builder().sender(userA).receiver(userB).status(InviteStatus.ACCEPTED).build();
        when(friendshipRepository.findBySenderUsernameAndReceiverUsername("userA", "userB")).thenReturn(Optional.of(friendship));

        assertThrows(IllegalStateException.class, () -> friendshipService.acceptInvite("userB", "userA"));
    }

    @Test
    void testDeleteFriendOrRejectInvite_Success() {
        Friendship friendship = Friendship.builder().sender(userA).receiver(userB).status(InviteStatus.ACCEPTED).build();
        when(friendshipRepository.findFriendshipBetween("userA", "userB")).thenReturn(Optional.of(friendship));

        friendshipService.deleteFriendOrRejectInvite("userA", "userB");

        verify(friendshipRepository, times(1)).delete(friendship);
    }
    
    @Test
    void testDeleteFriendOrRejectInvite_BlockedBySender() {
        Friendship friendship = Friendship.builder().sender(userA).receiver(userB).status(InviteStatus.BLOCKED).build();
        when(friendshipRepository.findFriendshipBetween("userA", "userB")).thenReturn(Optional.of(friendship));

        assertThrows(RuntimeException.class, () -> friendshipService.deleteFriendOrRejectInvite("userA", "userB"));
    }
    
    @Test
    void testDeleteFriendOrRejectInvite_BlockedByReceiver() {
        Friendship friendship = Friendship.builder().sender(userB).receiver(userA).status(InviteStatus.BLOCKED).build();
        when(friendshipRepository.findFriendshipBetween("userA", "userB")).thenReturn(Optional.of(friendship));

        // Receiver trying to delete should just silently return to hide block status
        assertDoesNotThrow(() -> friendshipService.deleteFriendOrRejectInvite("userA", "userB"));
        verify(friendshipRepository, never()).delete(any(Friendship.class));
    }

    @Test
    void testBlockUser_NewBlock() {
        when(userRepository.findByUsername("userA")).thenReturn(Optional.of(userA));
        when(userRepository.findByUsername("userB")).thenReturn(Optional.of(userB));
        when(friendshipRepository.findFriendshipBetween("userA", "userB")).thenReturn(Optional.empty());

        friendshipService.blockUser("userA", "userB");

        verify(friendshipRepository, times(1)).save(argThat(f -> f.getStatus() == InviteStatus.BLOCKED && f.getSender() == userA));
    }
    
    @Test
    void testBlockUser_ExistingFriendship() {
        when(userRepository.findByUsername("userA")).thenReturn(Optional.of(userA));
        when(userRepository.findByUsername("userB")).thenReturn(Optional.of(userB));
        
        Friendship friendship = Friendship.builder().sender(userB).receiver(userA).status(InviteStatus.ACCEPTED).build();
        when(friendshipRepository.findFriendshipBetween("userA", "userB")).thenReturn(Optional.of(friendship));

        friendshipService.blockUser("userA", "userB");

        assertEquals(InviteStatus.BLOCKED, friendship.getStatus());
        assertEquals(userA, friendship.getSender());
        verify(friendshipRepository, times(1)).save(friendship);
    }
    
    @Test
    void testBlockUser_PreventOverridingBlock() {
        when(userRepository.findByUsername("userA")).thenReturn(Optional.of(userA));
        when(userRepository.findByUsername("userB")).thenReturn(Optional.of(userB));
        
        Friendship friendship = Friendship.builder().sender(userB).receiver(userA).status(InviteStatus.BLOCKED).build();
        when(friendshipRepository.findFriendshipBetween("userA", "userB")).thenReturn(Optional.of(friendship));

        assertThrows(RuntimeException.class, () -> friendshipService.blockUser("userA", "userB"));
    }
    
    @Test
    void testUnblockUser() {
        Friendship friendship = Friendship.builder().sender(userA).receiver(userB).status(InviteStatus.BLOCKED).build();
        when(friendshipRepository.findBySenderUsernameAndReceiverUsername("userA", "userB")).thenReturn(Optional.of(friendship));
        
        friendshipService.unblockUser("userA", "userB");
        
        verify(friendshipRepository, times(1)).delete(friendship);
    }
    
    @Test
    void testGetFriendshipStatus_HidesBlockFromBlockedUser() {
        Friendship friendship = Friendship.builder().sender(userB).receiver(userA).status(InviteStatus.BLOCKED).build();
        when(friendshipRepository.findFriendshipBetween("userA", "userB")).thenReturn(Optional.of(friendship));
        
        FriendshipResponse response = friendshipService.getFriendshipStatus("userA", "userB");
        
        assertNull(response.status());
    }
}