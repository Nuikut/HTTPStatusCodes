FROM ubuntu@sha256:962f6cadeae0ea6284001009daa4cc9a8c37e75d1f5191cf0eb83fe565b63dd7

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates

WORKDIR /script

COPY Script/httpcodes.sh .

RUN chmod +x httpcodes.sh && useradd -u 10001 appuser && chown -R appuser:appuser /script

USER appuser

ENTRYPOINT ["/script/httpcodes.sh"]
