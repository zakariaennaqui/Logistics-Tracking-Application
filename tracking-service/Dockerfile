# Stage 1: Build from source (no need to upload JAR)
FROM maven:3.9-eclipse-temurin-17-alpine AS builder
WORKDIR /build

# Cache dependencies layer separately
COPY pom.xml .
RUN mvn dependency:go-offline -B -q 2>/dev/null || true

# Build the application
COPY src ./src
RUN mvn clean package -DskipTests -q

# Stage 2: Lightweight runtime image
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /build/target/*.jar app.jar

# HuggingFace Spaces uses port 7860
EXPOSE 7860
ENV PORT=7860
ENV JAVA_OPTS="-Xmx256m -Xms128m -XX:+UseSerialGC"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
