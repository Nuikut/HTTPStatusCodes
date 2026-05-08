#!/usr/bin/env bash
BASE_URL="https://tools-httpstatus.pickup-services.com"
REQUESTS_COUNT=5

log_info() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') | INFO | $1"
}

log_error() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') | ERROR | $1" >&2
}

curl_error() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') | CRITICAL | $1" >&2
}

raise_http_exception() {
  local status_code="$1"
  local url="$2"
  local body="$3"

  log_error "HTTP exception. URL: ${url}, Status code: ${status_code}, Body: ${body}"
  return 1
}

make_request() {
  local expected_status="$1"
  local url="${BASE_URL}/${expected_status}"

  log_info "Making request: GET ${url}"

  local response
  response=$(curl -sS --max-time 10 -w $'\n%{http_code}' "$url" 2>&1)

  local curl_exit_code=$?

  if [[ $curl_exit_code -ne 0 ]]; then
    curl_error "Got error whilst requesting. curl exit code: ${curl_exit_code}. Message: ${response}"
    return 2
  fi

  local status_code
  status_code=$(echo "$response" | tail -n 1)

  local body
  body=$(echo "$response" | sed '$d')

  if [[ $status_code -ge 100 && $status_code -le 399 ]]; then
    log_info "Successfully handled request. Status code: ${status_code}, Body: ${body}"

  elif [[ $status_code -ge 400 && $status_code -le 599 ]]; then
    raise_http_exception "$status_code" "$url" "$body"

  else
    log_error "Got unexpected HTTP code: ${status_code}. Body: ${body}"
    return 1
  fi
}

status_codes=(
  100 101 102 103 \
  200 201 202 203 204 205 206 207 208 226 \
  300 301 302 303 304 305 306 307 308 \
  400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417 418 421 422 423 424 425 426 428 429 431 451 \
  500 501 502 503 504 505 506 507 508 510 511 \
)

has_errors=0

for ((i = 1; i <= REQUESTS_COUNT; i++)); do
  status_code="${status_codes[$RANDOM % ${#status_codes[@]}]}"

  make_request "$status_code"
  exit_code=$?

  if [[ $exit_code -eq 1 ]]; then
    has_errors=1
  elif [[ $exit_code -eq 2 ]]; then
    has_errors=2
  fi
done

if [[ $has_errors == 1 ]]; then
  log_error "Script finished with errors"
  exit 0
fi

if [[ $has_errors == 2 ]]; then
  log_error "Script faced fatal errors"
  exit 1
fi

log_info "Script finished successfully"
exit 0
