# Stage 1: Builder Stage
FROM cgr.dev/chainguard/wolfi-base:latest AS builder

# Set env variable
ENV VAULT_VERSION=1.19.0

# Install required packages for building
RUN apk add --no-cache wget unzip binutils

# Download and verify Vault binary
RUN wget -q https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip \
    && unzip vault_${VAULT_VERSION}_linux_amd64.zip \
    && mv vault /usr/bin/vault \
    && strip /usr/bin/vault \
    && rm -f vault_${VAULT_VERSION}_linux_amd64.zip

# Stage 2: Minimal Runtime for Vault
FROM cgr.dev/chainguard/wolfi-base:latest

# Set env variable
ENV VAULT_ADDR=http://127.0.0.1:8200

# Copy the stripped Vault binary from the builder stage
COPY --from=builder /usr/bin/vault /usr/bin/vault

# Create a non-root user for security
RUN adduser -D -u 1001 vault-user

# Set appropriate permissions and switch to non-root user
USER vault-user
WORKDIR /home/vault-user

# Expose the Vault port
EXPOSE 8200

# Run Vault server
ENTRYPOINT ["vault"]
CMD ["server", "-dev", "-dev-listen-address=0.0.0.0:8200"]
