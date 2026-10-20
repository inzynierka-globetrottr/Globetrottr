package sniezynki.agh.globetrottr.user;

import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VerificationCodeRepository extends JpaRepository<VerificationCode, Long> {
    Optional<VerificationCode> findByCodeAndUserEmail(String code, String email);

    Optional<VerificationCode> findByUserEmail(String email);
}
