package sniezynki.agh.globetrottr.fog;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import sniezynki.agh.globetrottr.friend.FriendshipRepository;
import sniezynki.agh.globetrottr.friend.InviteStatus;
import sniezynki.agh.globetrottr.location.UserFogRepository;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class FogService {

    private final UserFogRepository userFogRepository;
    private final FriendshipRepository friendshipRepository;

    public String getUserFogGeoJson(String username) {
        return userFogRepository.findFogGeoJsonByUsername(username)
                .orElse(createEmptyGeoJson());
    }

    public String getFriendFogGeoJson(String currentUsername, String friendUsername) {
        boolean areFriends = friendshipRepository.findFriendshipBetween(currentUsername, friendUsername)
                .filter(friendship -> friendship.getStatus() == InviteStatus.ACCEPTED)
                .isPresent();

        if (!areFriends) {
            throw new IllegalArgumentException("You cannot view this user's map. You are not friends.");
        }

        return userFogRepository.findFogGeoJsonByUsername(friendUsername)
                .orElse(createEmptyGeoJson());
    }

    private String createEmptyGeoJson() {
        return "{\"type\": \"FeatureCollection\", \"features\": []}";
    }
}