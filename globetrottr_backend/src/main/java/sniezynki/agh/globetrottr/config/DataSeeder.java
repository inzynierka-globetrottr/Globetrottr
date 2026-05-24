package sniezynki.agh.globetrottr.config;

import lombok.RequiredArgsConstructor;
import org.locationtech.jts.geom.Geometry;
import org.locationtech.jts.io.ParseException;
import org.locationtech.jts.io.WKTReader;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import sniezynki.agh.globetrottr.quest.*;
import sniezynki.agh.globetrottr.user.User;
import sniezynki.agh.globetrottr.user.UserRepository;
import sniezynki.agh.globetrottr.user.UserRole;

import java.time.LocalDateTime;
import java.util.List;

@Component
@RequiredArgsConstructor
@Profile("!prod")
public class DataSeeder implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final QuestRepository questRepository;
    private final UserQuestRepository userQuestRepository;
    @Override
    public void run(String... args) {
        long userCount = userRepository.count();
        System.out.println("DataSeeder: Found " + userCount + " users in database.");

        if (userCount == 0) {
            System.out.println("DataSeeder: Database is empty. Seeding data...");
            User johnBiznes = User.builder()
                    .username("johnbiznes")
                    .email("john.biznes@globetrottr.com")
                    .isEmailVerified(true)
                    .passwordHash(passwordEncoder.encode("Johnbiznes1!"))
                    .role(UserRole.ADMIN)
                    .build();

            User secondAdmin = User.builder()
                    .username("adminuch")
                    .email("adminuch@globetrottr.com")
                    .isEmailVerified(true)
                    .passwordHash(passwordEncoder.encode("Zigibaza1!"))
                    .role(UserRole.ADMIN)
                    .build();

            User user1 = User.builder()
                    .username("jantester")
                    .email("jan@tester.com")
                    .isEmailVerified(true)
                    .passwordHash(passwordEncoder.encode("Test1!"))
                    .role(UserRole.USER)
                    .build();

            User user2 = User.builder()
                    .username("marekgarek")
                    .email("marek@garek.com")
                    .isEmailVerified(true)
                    .passwordHash(passwordEncoder.encode("Dziekan1!"))
                    .role(UserRole.USER)
                    .build();

            User user3 = User.builder()
                    .username("tortillla")
                    .email("tortilla@z.kurczakiem")
                    .isEmailVerified(true)
                    .passwordHash(passwordEncoder.encode("Zkurczakiem1!"))
                    .role(UserRole.USER)
                    .build();

            userRepository.saveAll(List.of(johnBiznes, secondAdmin, user1, user2, user3));
            System.out.println("DataSeeder: Successfully seeded " + userRepository.count() + " users.");
        }

        if (questRepository.count() == 0) {
            System.out.println("DataSeeder: Seeding quests...");

            Quest quest1 = Quest.builder()
                    .title("Zwiedzanie Starego Miasta")
                    .type(QuestType.VISIT_POINTS)
                    .questGeometry(createGeometry("MULTIPOINT(19.937222 50.061389, 19.938333 50.061667)"))
                    .rewardPoints(100)
                    .build();

            Quest quest2 = Quest.builder()
                    .title("Spacer Bulwarami Wiślanymi")
                    .type(QuestType.FOLLOW_ROUTE)
                    .questGeometry(createGeometry("LINESTRING(19.934 50.054, 19.937 50.053, 19.940 50.052)"))
                    .rewardPoints(250)
                    .build();
            questRepository.saveAll(List.of(quest1, quest2));
            System.out.println("DataSeeder: Successfully seeded " + questRepository.count() + " quests.");
        }
        if (userQuestRepository.count() == 0) {
            System.out.println("DataSeeder: Seeding user quests...");

            User testUser = userRepository.findByUsername("jantester").orElseThrow();
            List<Quest> allQuests = questRepository.findAll();

            if (allQuests.size() >= 2) {
                UserQuest activeQuest = UserQuest.builder()
                        .user(testUser)
                        .quest(allQuests.get(0))
                        .build();

                UserQuest completedQuest = UserQuest.builder()
                        .user(testUser)
                        .quest(allQuests.get(1))
                        .isCompleted(true)
                        .completedAt(LocalDateTime.now().minusDays(1))
                        .build();

                userQuestRepository.saveAll(List.of(activeQuest, completedQuest));
            }
        }

        System.out.println("DataSeeder: Finished successfully.");
    }


    private Geometry createGeometry(String wkt) {
        try {
            Geometry geometry = new WKTReader().read(wkt);
            geometry.setSRID(4326);
            return geometry;
        } catch (ParseException e) {
            throw new RuntimeException(e);
        }
    }
}