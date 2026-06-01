package sniezynki.agh.globetrottr.profile;

import com.cloudinary.Cloudinary;
import com.cloudinary.Uploader;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;
import sniezynki.agh.globetrottr.friend.Friendship;
import sniezynki.agh.globetrottr.friend.FriendshipRepository;
import sniezynki.agh.globetrottr.friend.InviteStatus;
import sniezynki.agh.globetrottr.profile.dto.UserProfileResponse;
import sniezynki.agh.globetrottr.user.User;
import sniezynki.agh.globetrottr.user.UserRepository;

import java.io.IOException;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyMap;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserProfileServiceTest {

    @Mock
    private UserProfileRepository userDetailsRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private FriendshipRepository friendshipRepository;

    @Mock
    private Cloudinary cloudinary;

    @Mock
    private Uploader uploader;

    @InjectMocks
    private UserProfileService userProfileService;

    private User userA;
    private User userB;

    @BeforeEach
    void setUp() {
        userA = User.builder().userId(UUID.randomUUID()).username("userA").totalPoints(100).build();
        userB = User.builder().userId(UUID.randomUUID()).username("userB").totalPoints(200).build();
    }

    @Test
    void shouldReturnMyProfile() {
        UserProfile profile = new UserProfile();
        profile.setBio("My Bio");
        profile.setAvatarUrl("http://image.com/me.jpg");

        when(userRepository.findByUsername("userA")).thenReturn(Optional.of(userA));
        when(userDetailsRepository.findByUser_Username("userA")).thenReturn(Optional.of(profile));

        UserProfileResponse response = userProfileService.getMyProfile("userA");

        assertEquals("userA", response.username());
        assertEquals("My Bio", response.bio());
        assertEquals("http://image.com/me.jpg", response.avatarUrl());
        assertEquals(100, response.totalPoints());
    }

    @Test
    void shouldReturnFriendProfileWhenFriends() {
        UserProfile profile = new UserProfile();
        profile.setBio("Friend Bio");

        Friendship friendship = Friendship.builder().status(InviteStatus.ACCEPTED).build();

        when(userRepository.findByUsername("userB")).thenReturn(Optional.of(userB));
        when(friendshipRepository.findFriendshipBetween("userA", "userB")).thenReturn(Optional.of(friendship));
        when(userDetailsRepository.findByUser_Username("userB")).thenReturn(Optional.of(profile));

        UserProfileResponse response = userProfileService.getFriendProfile("userA", "userB");

        assertEquals("userB", response.username());
        assertEquals("Friend Bio", response.bio());
        assertEquals(200, response.totalPoints());
    }

    @Test
    void shouldThrowExceptionWhenGettingFriendProfileAndNotFriends() {
        when(userRepository.findByUsername("userB")).thenReturn(Optional.of(userB));

        when(friendshipRepository.findFriendshipBetween("userA", "userB")).thenReturn(Optional.empty());

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
                () -> userProfileService.getFriendProfile("userA", "userB"));

        assertEquals("You cannot view this user's profile. You are not friends.", exception.getMessage());
    }

    @Test
    void shouldUpdateBioForExistingProfile() {
        UserProfile profile = new UserProfile();
        profile.setUser(userA);

        when(userDetailsRepository.findByUser_Username("userA")).thenReturn(Optional.of(profile));

        userProfileService.updateBio("userA", "New cool bio");

        assertEquals("New cool bio", profile.getBio());
        verify(userDetailsRepository, times(1)).save(profile);
    }

    @Test
    void shouldUploadAvatarAndSaveUrl() throws IOException {
        MockMultipartFile file = new MockMultipartFile("file", "test.jpg", "image/jpeg", "image_data".getBytes());
        UserProfile profile = new UserProfile();
        profile.setUser(userA);

        when(cloudinary.uploader()).thenReturn(uploader);
        when(uploader.upload(any(byte[].class), anyMap())).thenReturn(Map.of("secure_url", "http://cloudinary.com/test.jpg"));

        when(userDetailsRepository.findByUser_Username("userA")).thenReturn(Optional.of(profile));

        String url = userProfileService.uploadAvatar("userA", file);

        assertEquals("http://cloudinary.com/test.jpg", url);
        assertEquals("http://cloudinary.com/test.jpg", profile.getAvatarUrl());
        verify(userDetailsRepository, times(1)).save(profile);
    }

    @Test
    void shouldThrowExceptionWhenUploadingEmptyFile() {
        MockMultipartFile emptyFile = new MockMultipartFile("file", new byte[0]);

        IllegalArgumentException exception = assertThrows(IllegalArgumentException.class,
                () -> userProfileService.uploadAvatar("userA", emptyFile));

        assertEquals("File is empty", exception.getMessage());
    }
}