FROM eclipse-temurin:21-jdk-jammy AS builder

WORKDIR /app

# Copy gradle wrapper first for caching
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .
COPY static-weaving.gradle .
COPY buildSrc buildSrc
# Copy standard files
COPY APACHE_LICENSETEXT.md .
COPY NOTICE_RELEASE .
COPY NOTICE_SOURCE .
COPY LICENSE_RELEASE .
COPY LICENSE_SOURCE .

# Copy source code
COPY fineract-provider fineract-provider
# Copy other modules if needed (simplified for core build)
COPY fineract-api fineract-api
COPY fineract-core fineract-core
COPY fineract-client fineract-client
COPY fineract-accounting fineract-accounting
COPY fineract-branch fineract-branch
COPY fineract-charge fineract-charge
COPY fineract-command fineract-command
COPY fineract-doc fineract-doc
COPY fineract-document fineract-document
COPY fineract-investor fineract-investor
COPY fineract-loan fineract-loan
COPY fineract-progressive-loan fineract-progressive-loan
COPY fineract-rates fineract-rates
COPY fineract-report fineract-report
COPY fineract-savings fineract-savings
COPY fineract-tax fineract-tax
COPY fineract-validation fineract-validation
COPY integration-tests integration-tests
COPY custom custom

# Build the application
RUN ./gradlew :fineract-provider:bootJar -x test -x spotlessCheck -x rat

FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

COPY --from=builder /app/fineract-provider/build/libs/fineract-provider*.jar app.jar

ENV FINERACT_HIKARI_DRIVER_SOURCE_CLASS_NAME=org.postgresql.Driver

EXPOSE 8080

CMD ["java", "-Dloader.path=/app/libs", "-jar", "app.jar"]
