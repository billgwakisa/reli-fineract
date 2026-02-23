FROM eclipse-temurin:21-jdk-jammy AS builder

WORKDIR /app

# Copy gradle wrapper first for caching
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .
COPY gradle.properties .
COPY lombok.config .
COPY static-weaving.gradle .
COPY buildSrc buildSrc
# Copy standard files
COPY APACHE_LICENSETEXT.md .
COPY NOTICE_RELEASE .
COPY NOTICE_SOURCE .
COPY LICENSE_RELEASE .
COPY LICENSE_SOURCE .

# Copy source code
COPY fineract-core fineract-core
COPY fineract-cob fineract-cob
COPY fineract-validation fineract-validation
COPY fineract-command fineract-command
COPY fineract-accounting fineract-accounting
COPY fineract-provider fineract-provider
COPY fineract-branch fineract-branch
COPY fineract-document fineract-document
COPY fineract-investor fineract-investor
COPY fineract-rates fineract-rates
COPY fineract-charge fineract-charge
COPY fineract-tax fineract-tax
COPY fineract-loan-origination fineract-loan-origination
COPY fineract-loan fineract-loan
COPY fineract-savings fineract-savings
COPY fineract-report fineract-report
COPY fineract-war fineract-war
COPY integration-tests integration-tests
COPY fineract-client fineract-client
COPY fineract-client-feign fineract-client-feign
COPY fineract-doc fineract-doc
COPY fineract-avro-schemas fineract-avro-schemas
COPY fineract-e2e-tests-core fineract-e2e-tests-core
COPY fineract-e2e-tests-runner fineract-e2e-tests-runner
COPY fineract-progressive-loan fineract-progressive-loan
COPY fineract-progressive-loan-embeddable-schedule-generator fineract-progressive-loan-embeddable-schedule-generator
COPY custom custom

# Set Gradle options - Sequential build with Serial GC to minimize memory overhead
# We leave ~4GB for the host/container overhead
ENV GRADLE_OPTS="-Xmx8g -Xms512m -XX:+UseSerialGC -Dorg.gradle.daemon=false -Dorg.gradle.parallel=false -Dorg.gradle.workers.max=1 -Dorg.gradle.internal.http.socketTimeout=60000 -Dorg.gradle.internal.http.connectionTimeout=60000"

# Forcefully override the 12G heap in gradle.properties to match our container limit
RUN sed -i 's/-Xmx12g/-Xmx8g/g' gradle.properties

# Build the application - strictly skip tests and checks
RUN ./gradlew :fineract-provider:bootJar \
    --no-daemon \
    --no-parallel \
    -x test \
    -x testClasses \
    -x compileTestJava \
    -x spotlessCheck \
    -x rat \
    -x check \
    -x spotlessJava \
    -x spotlessMisc \
    -x checkstyleMain \
    -x checkstyleTest \
    -x spotbugsMain \
    -x spotbugsTest \
    -x modernizer \
    -x licenseMain \
    -x licenseTest

FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

COPY --from=builder /app/fineract-provider/build/libs/fineract-provider*.jar app.jar

ENV FINERACT_HIKARI_DRIVER_SOURCE_CLASS_NAME=org.postgresql.Driver

EXPOSE 8080

CMD ["java", "-Dloader.path=/app/libs", "-jar", "app.jar"]
