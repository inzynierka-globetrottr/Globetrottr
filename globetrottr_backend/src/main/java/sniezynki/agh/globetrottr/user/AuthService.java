package sniezynki.agh.globetrottr.user;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import sniezynki.agh.globetrottr.security.JwtService;
import sniezynki.agh.globetrottr.user.dto.AuthRequest;
import sniezynki.agh.globetrottr.user.dto.AuthResponse;
import sniezynki.agh.globetrottr.user.dto.RegisterRequest;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;

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
        var jwtToken = jwtService.generateToken(user);

        return AuthResponse.builder()
                .token(jwtToken)
                .build();
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

        var jwtToken = jwtService.generateToken(user);
        return AuthResponse.builder()
                .token(jwtToken)
                .build();
    }

    public AuthResponse refreshToken(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new RuntimeException("Invalid token");
        }

        String token = authHeader.substring(7);
        String username = jwtService.extractUsername(token);

        var  user = userRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("Invalid username"));

        if (jwtService.isTokenValid(token, user)) {
            var newToken = jwtService.generateToken(user);
            return AuthResponse.builder()
                    .token(newToken)
                    .build();
        }
        throw new RuntimeException("Invalid token");
    }
}