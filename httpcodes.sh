#!/usr/bin/env bash

BASE_URL="https://tools-httpstatus.pickup-services.com"

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
    curl_error "Got error whilst requesting ${url}. curl exit code: ${curl_exit_code}. Message: ${response}"
    return 1
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
#200 201 202 203 204 205 206 207 208 226 \
#300 301 302 303 304 305 306 307 308 \
#400 401 402 403 404 405 406 407 408 409 410 411 412 413 414 415 416 417 418 421 422 423 424 425 426 428 429 431 451 \
#500 501 502 503 504 505 506 507 508 510 511 \
#200 201 300 404 511
)

for status_code in "${status_codes[@]}"; do
make_request "$status_code"
done
