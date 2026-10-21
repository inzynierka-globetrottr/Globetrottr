FROM gradle:jdk25-alpine AS builder
WORKDIR /app

COPY . .

RUN chmod +x ./gradlew && \
    ./gradlew bootJar --no-daemon

FROM eclipse-temurin:25-jre-alpine
WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring
COPY --chown=spring:spring --from=builder /app/build/libs/*.jar app.jar
USER spring:spring

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]