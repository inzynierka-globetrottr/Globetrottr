package sniezynki.agh.globetrottr.friend;

import org.springframework.stereotype.Service;
import sniezynki.agh.globetrottr.friend.dto.FriendshipRequest;

import java.util.List;

@Service
public class FriendshipService {
    public List<Friendship> getUserFriends(String username) {
        
    }

    public Friendship sendInvite(FriendshipRequest request) {
    }
}
