package sniezynki.agh.globetrottr.friend;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import sniezynki.agh.globetrottr.friend.dto.FriendshipRequest;
import sniezynki.agh.globetrottr.friend.dto.FriendshipResponse;

import java.util.List;

@RestController
@RequestMapping("/api/friends")
@RequiredArgsConstructor
public class FriendshipController {
    private final FriendshipService friendshipService;

    @GetMapping
    public ResponseEntity<List<FriendshipResponse>> getFriendships() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(friendshipService.getUserFriends(username));
    }

    @GetMapping("/invites")
    public ResponseEntity<List<FriendshipResponse>> getFriendRequests() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(friendshipService.getUserFriendRequests(username));
    }

    @GetMapping("/invites/sent")
    public ResponseEntity<List<FriendshipResponse>> getSentFriendRequests() {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(friendshipService.getSentFriendRequests(username));
    }

    @GetMapping("/{targetUsername}/status")
    public ResponseEntity<FriendshipResponse> getFriendshipStatus(@PathVariable String targetUsername) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(friendshipService.getFriendshipStatus(username, targetUsername));
    }

    @PostMapping("/invites")
    public ResponseEntity<Void> sendInvite(@RequestBody FriendshipRequest request) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        friendshipService.sendInvite(username, request.username());
        return ResponseEntity.ok().build();
    }

    @PostMapping("/invites/{targetUsername}/accept")
    public ResponseEntity<Void> acceptInvite(@PathVariable String targetUsername) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        friendshipService.acceptInvite(username, targetUsername);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{targetUsername}")
    public ResponseEntity<Void> deleteFriendOrRejectInvite(@PathVariable String targetUsername) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        friendshipService.deleteFriendOrRejectInvite(username, targetUsername);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{targetUsername}/block")
    public ResponseEntity<Void> blockUser(@PathVariable String targetUsername) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        friendshipService.blockUser(username, targetUsername);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{targetUsername}/block")
    public ResponseEntity<Void> unblockUser(@PathVariable String targetUsername) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        friendshipService.unblockUser(username, targetUsername);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/search")
    public ResponseEntity<List<FriendshipResponse>> searchUsers(@RequestParam String query) {
        String username = SecurityContextHolder.getContext().getAuthentication().getName();
        return ResponseEntity.ok(friendshipService.searchUsers(username, query));
    }
}