package sniezynki.agh.globetrottr;

import org.springframework.boot.SpringApplication;

public class TestGlobetrottrApplication {

    public static void main(String[] args) {
        SpringApplication.from(GlobetrottrApplication::main).with(TestcontainersConfiguration.class).run(args);
    }

}
