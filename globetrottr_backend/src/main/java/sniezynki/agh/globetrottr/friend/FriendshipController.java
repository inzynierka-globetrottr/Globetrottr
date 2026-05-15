package sniezynki.agh.globetrottr.friend;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import sniezynki.agh.globetrottr.friend.dto.FriendshipRequest;

import java.util.List;

@RestController
@RequestMapping("/api/friends")
@RequiredArgsConstructor
public class FriendshipController {
    private final FriendshipRepository friendshipRepository;
    private final FriendshipService friendshipService;

    @GetMapping
    public ResponseEntity<List<Friendship>> getFriendships(@PathVariable String username) {
        return ResponseEntity.ok(friendshipService.getUserFriends(username);
    }

    @PostMapping
    public ResponseEntity<Friendship> sendInvite(@RequestBody FriendshipRequest request) {
        return ResponseEntity.ok(friendshipService.sendInvite(request);
    }
}
