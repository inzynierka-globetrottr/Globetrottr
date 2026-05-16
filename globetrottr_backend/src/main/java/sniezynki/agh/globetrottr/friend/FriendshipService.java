package sniezynki.agh.globetrottr.friend;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sniezynki.agh.globetrottr.friend.dto.FriendshipResponse;
import sniezynki.agh.globetrottr.user.User;
import sniezynki.agh.globetrottr.user.UserRepository;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FriendshipService {

    private final FriendshipRepository friendshipRepository;
    private final UserRepository userRepository;

    public List<FriendshipResponse> getUserFriends(String username) {
        return friendshipRepository.findAllUserFriendships(username).stream()
                .filter(friendship -> friendship.getStatus() == InviteStatus.ACCEPTED)
                .map(friendship -> {
                    String friendUsername = getOtherUsername(friendship, username);
                    return new FriendshipResponse(friendUsername, friendship.getStatus(), false);
                })
                .toList();
    }

    public List<FriendshipResponse> getUserFriendRequests(String username) {
        return friendshipRepository.findAllUserFriendships(username).stream()
                .filter(friendship -> friendship.getStatus() == InviteStatus.PENDING)
                .filter(friendship -> friendship.getReceiver().getUsername().equals(username))
                .map(friendship -> new FriendshipResponse(friendship.getSender().getUsername(), friendship.getStatus(), true))
                .toList();
    }

    public List<FriendshipResponse> getSentFriendRequests(String currentUsername) {
        return friendshipRepository.findAllUserFriendships(currentUsername).stream()
                .filter(friendship -> friendship.getStatus() == InviteStatus.PENDING)
                .filter(friendship -> friendship.getSender().getUsername().equals(currentUsername))
                .map(friendship -> new FriendshipResponse(friendship.getReceiver().getUsername(), friendship.getStatus(), false))
                .toList();
    }

    public FriendshipResponse getFriendshipStatus(String currentUsername, String targetUsername) {
        return friendshipRepository.findFriendshipBetween(currentUsername, targetUsername)
                .map(friendship -> {
                    if (friendship.getStatus() == InviteStatus.BLOCKED && !friendship.getSender().getUsername().equals(currentUsername)) {
                        return new FriendshipResponse(targetUsername, null, false);
                    }
                    boolean isIncoming = friendship.getReceiver().getUsername().equals(currentUsername)
                            && friendship.getStatus() == InviteStatus.PENDING;
                    return new FriendshipResponse(targetUsername, friendship.getStatus(), isIncoming);
                })
                .orElse(new FriendshipResponse(targetUsername, null, false));
    }

    @Transactional
    public void sendInvite(String senderUsername, String targetUsername) {
        if (senderUsername.equals(targetUsername)) {
            throw new IllegalArgumentException("You cannot invite yourself");
        }

        var existingFriendship = friendshipRepository.findFriendshipBetween(senderUsername, targetUsername);

        if (existingFriendship.isPresent()) {
            InviteStatus status = existingFriendship.get().getStatus();

            if (status == InviteStatus.ACCEPTED) {
                throw new RuntimeException("You are already friends");
            } else if (status == InviteStatus.PENDING) {
                throw new RuntimeException("Invitation is already pending");
            } else if (status == InviteStatus.BLOCKED) {
                if (existingFriendship.get().getSender().getUsername().equals(senderUsername)) {
                    throw new RuntimeException("You must unblock this user before sending an invitation");
                } else {
                    throw new RuntimeException("Cannot send invitation to this user");
                }
            }
        }

        User sender = userRepository.findByUsername(senderUsername)
                .orElseThrow(() -> new IllegalArgumentException("Sender not found"));
        User receiver = userRepository.findByUsername(targetUsername)
                .orElseThrow(() -> new IllegalArgumentException("Receiver not found"));

        Friendship friendship = Friendship.builder()
                .sender(sender)
                .receiver(receiver)
                .status(InviteStatus.PENDING)
                .build();

        friendshipRepository.save(friendship);
    }

    @Transactional
    public void acceptInvite(String currentUsername, String senderUsername) {
        Friendship friendship = friendshipRepository.findBySenderUsernameAndReceiverUsername(senderUsername, currentUsername)
                .orElseThrow(() -> new IllegalArgumentException("Invite not found"));

        if (friendship.getStatus() != InviteStatus.PENDING) {
            throw new IllegalStateException("Cannot accept an invite that is not pending");
        }

        friendship.setStatus(InviteStatus.ACCEPTED);
        friendshipRepository.save(friendship);
    }

    @Transactional
    public void deleteFriendOrRejectInvite(String currentUsername, String targetUsername) {
        friendshipRepository.findFriendshipBetween(currentUsername, targetUsername)
                .ifPresent(friendship -> {
                    if (friendship.getStatus() == InviteStatus.BLOCKED) {
                        // EDGE CASE: If the blocked user tries to delete the relationship, ignore it to prevent leaking block status
                        if (!friendship.getSender().getUsername().equals(currentUsername)) {
                            return; 
                        }
                        throw new RuntimeException("You cannot delete a blocked relationship, you must unblock first");
                    }
                    friendshipRepository.delete(friendship);
                });
    }

    @Transactional
    public void blockUser(String currentUsername, String targetUsername) {
        User blocker = userRepository.findByUsername(currentUsername)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        User blocked = userRepository.findByUsername(targetUsername)
                .orElseThrow(() -> new IllegalArgumentException("Target user not found"));
        if (currentUsername.equals(targetUsername)) {
            throw new IllegalArgumentException("You cannot block yourself");
        }

        friendshipRepository.findFriendshipBetween(currentUsername, targetUsername)
                .ifPresentOrElse(
                        existingFriendship -> {
                            if (existingFriendship.getStatus() == InviteStatus.BLOCKED
                                    && existingFriendship.getReceiver().getUsername().equals(currentUsername)) {
                                throw new RuntimeException("Cannot block this user");
                            }
                            existingFriendship.setStatus(InviteStatus.BLOCKED);
                            existingFriendship.setSender(blocker);
                            existingFriendship.setReceiver(blocked);
                            friendshipRepository.save(existingFriendship);
                        },
                        () -> {
                            Friendship newBlock = Friendship.builder()
                                    .sender(blocker)
                                    .receiver(blocked)
                                    .status(InviteStatus.BLOCKED)
                                    .build();
                            friendshipRepository.save(newBlock);
                        }
                );
    }

    @Transactional
    public void unblockUser(String currentUsername, String targetUsername) {
        friendshipRepository.findBySenderUsernameAndReceiverUsername(currentUsername, targetUsername)
                .filter(friendship -> friendship.getStatus() == InviteStatus.BLOCKED)
                .ifPresent(friendshipRepository::delete);
    }

    public List<FriendshipResponse> searchUsers(String currentUsername, String query) {
        if (query == null || query.trim().length() < 3) {
            return List.of();
        }

        return userRepository.findByUsernameContainingIgnoreCase(query).stream()
                .filter(user -> !user.getUsername().equals(currentUsername))
                .map(user -> {
                    InviteStatus status = null;
                    boolean isIncoming = false;

                    var friendshipOpt = friendshipRepository.findFriendshipBetween(currentUsername, user.getUsername());
                    if (friendshipOpt.isPresent()) {
                        Friendship friendship = friendshipOpt.get();
                        
                        if (friendship.getStatus() != InviteStatus.BLOCKED || friendship.getSender().getUsername().equals(currentUsername)) {
                            status = friendship.getStatus();
                            isIncoming = friendship.getReceiver().getUsername().equals(currentUsername)
                                    && status == InviteStatus.PENDING;
                        }
                    }

                    return new FriendshipResponse(user.getUsername(), status, isIncoming);
                })
                .filter(response -> response.status() != InviteStatus.BLOCKED)
                .toList();
    }

    private String getOtherUsername(Friendship friendship, String currentUsername) {
        return friendship.getSender().getUsername().equals(currentUsername)
                ? friendship.getReceiver().getUsername()
                : friendship.getSender().getUsername();
    }
}