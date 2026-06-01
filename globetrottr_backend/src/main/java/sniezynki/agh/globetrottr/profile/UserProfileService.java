package sniezynki.agh.globetrottr.profile;

import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import sniezynki.agh.globetrottr.friend.FriendshipRepository;
import sniezynki.agh.globetrottr.friend.InviteStatus;
import sniezynki.agh.globetrottr.profile.dto.UserProfileResponse;
import sniezynki.agh.globetrottr.user.User;
import sniezynki.agh.globetrottr.user.UserRepository;

import java.io.IOException;

@Service
@RequiredArgsConstructor
public class UserProfileService {

    private final UserProfileRepository userProfileRepository;
    private final UserRepository userRepository;
    private final FriendshipRepository friendshipRepository;
    private final Cloudinary cloudinary;

    @Transactional(readOnly = true)
    public UserProfileResponse getMyProfile(String username) {
        return buildProfileResponse(username);
    }

    @Transactional(readOnly = true)
    public UserProfileResponse getFriendProfile(String username, String friendUsername) {
        userRepository.findByUsername(friendUsername)
                .orElseThrow(() -> new IllegalArgumentException("Target user not found"));

        boolean areFriends = friendshipRepository.findFriendshipBetween(username, friendUsername)
                .filter(friendship -> friendship.getStatus() == InviteStatus.ACCEPTED)
                .isPresent();

        if (!areFriends) {
            throw new IllegalArgumentException("You cannot view this user's profile. You are not friends.");
        }

        return buildProfileResponse(friendUsername);
    }

    @Transactional
    public void updateBio(String username, String newBio) {
        UserProfile userProfile = getOrCreateUserProfile(username);
        userProfile.setBio(newBio);
        userProfileRepository.save(userProfile);
    }

    @Transactional
    public String uploadAvatar(String username, MultipartFile file) {
        if (file.isEmpty()) {
            throw new IllegalArgumentException("File is empty");
        }

        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new IllegalArgumentException("Only image files are allowed");
        }

        try {
            var uploadResult = cloudinary.uploader().upload(file.getBytes(), ObjectUtils.asMap(
                    "folder", "globetrottr/avatars",
                    "transformation", "c_fill,g_face,w_400,h_400"
            ));

            String secureUrl = uploadResult.get("secure_url").toString();

            UserProfile userProfile = getOrCreateUserProfile(username);
            userProfile.setAvatarUrl(secureUrl);
            userProfileRepository.save(userProfile);

            return secureUrl;

        } catch (IOException e) {
            throw new RuntimeException("Image upload failed", e);
        }
    }

    // Helpers

    private UserProfileResponse buildProfileResponse(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        UserProfile userProfile = userProfileRepository.findByUser_Username(username)
                .orElse(new UserProfile());

        return UserProfileResponse.builder()
                .username(user.getUsername())
                .avatarUrl(userProfile.getAvatarUrl())
                .bio(userProfile.getBio())
                .totalPoints(user.getTotalPoints() != null ? user.getTotalPoints() : 0)
                .build();
    }

    private UserProfile getOrCreateUserProfile(String username) {
        return userProfileRepository.findByUser_Username(username)
                .orElseGet(() -> {
                    User user = userRepository.findByUsername(username)
                            .orElseThrow(() -> new IllegalArgumentException("User not found"));
                    UserProfile userProfile = new UserProfile();
                    userProfile.setUser(user);
                    return userProfile;
                });
    }
}