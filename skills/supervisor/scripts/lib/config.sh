#!/usr/bin/env bash

_supervisor_config_error() {
  printf 'Error: %s\n' "$1" >&2
}

_supervisor_read_merged_config() {
  local config_path

  if command -v opencode >/dev/null 2>&1; then
    if ! opencode debug config; then
      _supervisor_config_error \
        "could not read merged OpenCode config with: opencode debug config"
      return 1
    fi
    return 0
  fi

  if [[ -n ${XDG_CONFIG_HOME:-} ]]; then
    config_path="${XDG_CONFIG_HOME}/opencode/opencode.json"
  elif [[ -n ${HOME:-} ]]; then
    config_path="${HOME}/.config/opencode/opencode.json"
  else
    _supervisor_config_error \
      "opencode is unavailable and neither XDG_CONFIG_HOME nor HOME is set"
    return 1
  fi

  if [[ ! -r $config_path ]]; then
    _supervisor_config_error \
      "opencode is unavailable and OpenCode JSON config is not readable: ${config_path}"
    return 1
  fi

  printf '%s\n' "$(<"$config_path")"
}

_supervisor_load_config() {
  local merged_config
  local base_url
  local api_key
  local model

  if ! command -v jq >/dev/null 2>&1; then
    _supervisor_config_error "required command not found: jq"
    return 1
  fi

  if ! merged_config=$(_supervisor_read_merged_config); then
    return 1
  fi

  if ! jq -e . >/dev/null 2>&1 <<<"$merged_config"; then
    _supervisor_config_error \
      "merged OpenCode configuration is not valid JSON"
    return 1
  fi

  if ! jq -e \
    '.provider.supervisor.options | type == "object"' \
    >/dev/null 2>&1 <<<"$merged_config"; then
    _supervisor_config_error \
      "supervisor config is missing at provider.supervisor.options; add it to OpenCode config (see SKILL.md for the schema)"
    return 1
  fi

  if ! base_url=$(jq -er \
    '.provider.supervisor.options.baseUrl
      | select(type == "string" and length > 0)' \
    <<<"$merged_config"); then
    _supervisor_config_error \
      "supervisor config field provider.supervisor.options.baseUrl is required"
    return 1
  fi

  if ! api_key=$(jq -er \
    '.provider.supervisor.options.apiKey
      | select(type == "string" and length > 0)' \
    <<<"$merged_config"); then
    _supervisor_config_error \
      "supervisor config field provider.supervisor.options.apiKey is required"
    return 1
  fi

  if ! model=$(jq -er \
    '.provider.supervisor.options.model
      | select(type == "string" and length > 0)' \
    <<<"$merged_config"); then
    _supervisor_config_error \
      "supervisor config field provider.supervisor.options.model is required"
    return 1
  fi

  while [[ $base_url == */ ]]; do base_url=${base_url%/}; done

  if [[ -z $base_url ]]; then
    _supervisor_config_error \
      "supervisor config field provider.supervisor.options.baseUrl is required"
    return 1
  fi

  readonly SUPERVISOR_API_URL="${base_url}/v1/chat/completions"
  readonly SUPERVISOR_API_KEY="$api_key"
  readonly SUPERVISOR_MODEL="$model"
}

if ! _supervisor_load_config; then
  unset -f \
    _supervisor_config_error \
    _supervisor_read_merged_config \
    _supervisor_load_config
  return 1 2>/dev/null || exit 1
fi

unset -f \
  _supervisor_config_error \
  _supervisor_read_merged_config \
  _supervisor_load_config
