package sniezynki.agh.globetrottr.friend;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface FriendshipRepository extends JpaRepository<Friendship, Long> {

    @Query("""
            SELECT f FROM Friendship f
            WHERE (f.sender.username = :userA AND f.receiver.username = :userB)
               OR (f.sender.username = :userB AND f.receiver.username = :userA)
            """)
    Optional<Friendship> findFriendshipBetween(@Param("userA") String userA, @Param("userB") String userB);

    @Query("""
            SELECT f FROM Friendship f
            WHERE f.sender.username = :username
               OR f.receiver.username = :username
            """)
    List<Friendship> findAllUserFriendships(@Param("username") String username);

    Optional<Friendship> findBySenderUsernameAndReceiverUsername(String sender, String receiver);
}