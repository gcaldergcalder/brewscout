package com.brewscout.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            // We only need GET health endpoints to be open; everything else can stay secured.
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/v1/health", "/actuator/health").permitAll()
                .anyRequest().authenticated()
            )
            // For learning / simplicity, keep HTTP Basic and disable CSRF (better tuned later).
            .httpBasic(httpBasic -> {})
            .csrf(csrf -> csrf.disable());

        return http.build();
    }
}


