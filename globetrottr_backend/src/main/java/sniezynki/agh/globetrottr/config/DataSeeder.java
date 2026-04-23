package sniezynki.agh.globetrottr.config;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import sniezynki.agh.globetrottr.user.User;
import sniezynki.agh.globetrottr.user.UserRepository;
import sniezynki.agh.globetrottr.user.UserRole;

import java.util.List;

@Component
@RequiredArgsConstructor
@Profile("dev")
public class DataSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        long userCount = userRepository.count();
        System.out.println("DataSeeder: Found " + userCount + " users in database.");
        if (userRepository.count() == 0) {
            System.out.println("DataSeeder: Database is empty. Seeding data...");
            User johnBiznes = User.builder()
                    .username("johnbiznes")
                    .email("john.biznes@globetrottr.com")
                    .passwordHash(passwordEncoder.encode("JohnBiznesAdmin"))
                    .role(UserRole.ADMIN)
                    .build();

            User secondAdmin = User.builder()
                    .username("adminuch")
                    .email("adminuch@globetrottr.com")
                    .passwordHash(passwordEncoder.encode("zigibaza"))
                    .role(UserRole.ADMIN)
                    .build();

            User user1 = User.builder()
                    .username("jantester")
                    .email("jan@tester.com")
                    .passwordHash(passwordEncoder.encode("test"))
                    .role(UserRole.USER)
                    .build();

            User user2 = User.builder()
                    .username("marekgarek")
                    .email("marek@garek.com")
                    .passwordHash(passwordEncoder.encode("dziekan123"))
                    .role(UserRole.USER)
                    .build();

            User user3 = User.builder()
                    .username("tortillla")
                    .email("tortilla@z.kurczakiem")
                    .passwordHash(passwordEncoder.encode("zKurczakiem"))
                    .role(UserRole.USER)
                    .build();

            userRepository.saveAll(List.of(johnBiznes, secondAdmin, user1, user2, user3));
            System.out.println("DataSeeder: Successfully seeded " + userRepository.count() + " users.");
        }
    }
}