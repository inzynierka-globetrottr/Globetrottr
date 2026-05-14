package sniezynki.agh.globetrottr.user;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import sniezynki.agh.globetrottr.email.EmailService;
import sniezynki.agh.globetrottr.security.JwtService;
import sniezynki.agh.globetrottr.user.dto.*;

import java.sql.Timestamp;
import java.util.Collections;
import java.util.Random;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final VerificationCodeRepository verificationCodeRepository;
    private final EmailService emailService;

    @Value("${google.client.id}")
    private String googleClientId;

    public AuthResponse register(RegisterRequest request) {
        var normalizedUsername = request.username().toLowerCase().trim();
        var normalizedEmail = request.email().toLowerCase().trim();

        if(userRepository.findByEmail(normalizedEmail).isPresent()) {
            throw new RuntimeException("Email already exists");
        }
        if(userRepository.findByUsername(normalizedUsername).isPresent()) {
            throw new RuntimeException("Username already exists");
        }

        var user = User.builder()
                .username(normalizedUsername)
                .email(normalizedEmail)
                .passwordHash(passwordEncoder.encode(request.password()))
                .role(UserRole.USER)
                .build();

        userRepository.save(user);

        String code = String.format("%06d", new Random().nextInt(1000000));
        VerificationCode verificationCode = VerificationCode.builder()
                .code(code)
                .user(user)
                .expiryDate(new Timestamp(System.currentTimeMillis() + 1000 * 60 * 15))
                .build();
        verificationCodeRepository.save(verificationCode);
        emailService.sendVerificationEmail(user.getEmail(), code);


        return AuthResponse.builder().token("").build();
    }

    public AuthResponse authenticate(AuthRequest request) {
        var normalizedLogin = request.login().toLowerCase().trim();

        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        normalizedLogin,
                        request.password()
                )
        );

        var user = userRepository.findByUsernameOrEmail(normalizedLogin, normalizedLogin)
                .orElseThrow();

        if (!user.isEmailVerified()) {
            throw new BadCredentialsException("Email not verified");
        }

        var jwtToken = jwtService.generateToken(user);
        return AuthResponse.builder()
                .token(jwtToken)
                .build();
    }

    public AuthResponse authenticateWithGoogle(GoogleAuthRequest request) {
        GoogleIdToken idToken;

        try {
            GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(new NetHttpTransport(), new GsonFactory())
             // Comment  line below to test google login using https://developers.google.com/oauthplayground/
             .setAudience(Collections.singletonList(googleClientId))
                    .build();

            idToken = verifier.verify(request.token());
        } catch (Exception e) {
            throw new BadCredentialsException("Failed to verify Google token");
        }

        if (idToken == null) {
            throw new BadCredentialsException("Invalid Google ID token.");
        }

        GoogleIdToken.Payload payload = idToken.getPayload();
        String email = payload.getEmail();
        String name = (String) payload.get("name");

        User user = userRepository.findByEmail(email).orElseGet(() -> {
            User newUser = User.builder()
                    .username(name.replaceAll("\\s+", "").toLowerCase() + UUID.randomUUID().toString().substring(0, 5))
                    .email(email)
                    .passwordHash(null)
                    .authProvider(AuthProvider.GOOGLE)
                    .isEmailVerified(true)
                    .role(UserRole.USER)
                    .build();
            return userRepository.save(newUser);
        });

        if (!user.isEmailVerified()) {
            user.setEmailVerified(true);
            userRepository.save(user);
        }

        var jwtToken = jwtService.generateToken(user);

        return AuthResponse.builder()
                .token(jwtToken)
                .build();
    }

    public AuthResponse verifyEmail(VerifyEmailRequest request) {
        VerificationCode verificationCode = verificationCodeRepository
                .findByCodeAndUserEmail(request.code(), request.email())
                .orElseThrow(() -> new IllegalArgumentException("Invalid mail or verification code"));

        if (verificationCode.getExpiryDate().getTime() < System.currentTimeMillis()) {
            throw new IllegalArgumentException("Verification code expired");
        }

        User user = verificationCode.getUser();
        user.setEmailVerified(true);
        userRepository.save(user);
        verificationCodeRepository.delete(verificationCode);

        String jwtToken = jwtService.generateToken(user);

        return AuthResponse.builder()
                .token(jwtToken)
                .build();
    }

    public void resendVerificationCode(ResendCodeRequest request) {
        var normalizedEmail = request.email().toLowerCase().trim();

        User user = userRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        if (user.isEmailVerified()) {
            throw new BadCredentialsException("Email already verified");
        }

        verificationCodeRepository.findByUserEmail(normalizedEmail)
                .ifPresent(verificationCodeRepository::delete);

        String newCode = String.format("%06d", new Random().nextInt(1000000));

        VerificationCode verificationCode = VerificationCode.builder()
                .code(newCode)
                .user(user)
                .expiryDate(new Timestamp(System.currentTimeMillis() + 1000 * 60 * 15))
                .build();

        verificationCodeRepository.save(verificationCode);
        emailService.sendVerificationEmail(user.getEmail(), newCode);
    }
}