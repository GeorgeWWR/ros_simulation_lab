#!/bin/bash -eu
# Launch the development environment container.

function usage() {
  echo "This script launches the NASA SBIR development environment."
  echo
  echo "Usage:"
  echo "  --build          -- Build the Docker image."
  echo "  --dev-env-name   -- The name of the development environment. Default dev-env."
  echo "  --docker-image   -- The docker image to use. Defaults to dev-base."
  echo "  --docker-repo    -- The docker repository to use. Defaults to winterwindsroboticsdocker."
  echo "  --docker-tag     -- The docker tag to use. Defaults to the recommended version."
  echo "  --force-cpu      -- Do not use a GPU, even if one is detected."
  echo "  --force-gpu      -- Attempt to use a GPU even if one is not detected."
  echo "  --force-recreate -- Destroy any existing development environment with the same name."
  echo "  --gpu-card       -- Which card to use, by index. Default 0. See /dev/dri/card* for indices."
  echo "  --help           -- Display this message."
  echo "  --ngrok          -- Launch ngrok when the development environment starts."
  echo "  --ngrok-token    -- Configure ngrok with a token."
  echo "  --no-launch      -- Do not launch a browser to the VNC server, or a bash shell if using X11."
  echo "  --no-pull        -- Do not attempt to pull the Docker image."
  echo "  --novnc-port     -- The host port to bind for novnc (web-based). Default 8080."
  echo "  --push           -- Push the Docker image to the repository."
  echo "                      If this is selected, then a devevelopment environment won't be spawned,"
  echo "                      the image will just be pushed."
  echo "  --resolution     -- The VNC server's initial display resoultion. Default 3840x2160."
  echo "  --use-host-x     -- Instead of launching a VNC server, use the host's existing X11 server."
  echo "  --user-password  -- The password for the wwr user. Required for use of sudo."
  echo "                      defaults to empty, meaning wwr has no password and cannot use sudo."
  echo "  --vnc-port       -- The host port to bind for standard VNC. Default 5901."
  echo
  echo "Note, some parameters may also be set via environment variables:"
  echo "  BUILD_IMAGE    -- If true, build the Docker image, otherwise do not build it."
  echo "  DEV_ENV_NAME   -- The name of the development environment. Can be used to have multiple"
  echo "                    development environments simultaneously."
  echo "  DOCKER_IMAGE   -- The docker image to use."
  echo "  DOCKER_REPO    -- The docker repository to use."
  echo "  DOCKER_TAG     -- The docker tag to use."
  echo "  FORCE_RECREATE -- Destroy any existing development environment with the same name."
  echo "  GPU            -- If auto then detect a GPU. If true then use a GPU. If false use CPU."
  echo "  GPU_CARD       -- The GPU card number to use when doing GPU acceleration inside VNC."
  echo "  LAUNCH         -- If true then launch a browser/shell, if false don't launch a browser/shell."
  echo "  NGROK          -- If true start ngrok to share the VNC server publicly."
  echo "  NGROK_TOKEN    -- The ngrok auth token to use. Not required, but useful for keeping the"
  echo "                    tunnel open for longer than 8 hours."
  echo "  NOVNC_PORT     -- The host port to bind for novnc (web-based)."
  echo "  PULL_IMAGE     -- If true, attempt to pull the Docker image, otherwise don't."
  echo "  PUSH_IMAGE     -- If true, attempt to push the Docker image, otherwise don't."
  echo "  RESOLUTION     -- The VNC server's initial display resoultion. Default 3840x2160."
  echo "  USER_PASSWORD  -- The password to set for the wwr user, in order to use sudo."
  echo "  VNC            -- If true then launch a VNC server, if false use the host's X11 server."
  echo "  VNC_PASSWORD   -- The VNC password to use."
  echo "  VNC_PORT       -- The host port to bind for standard VNC."
}

# Get values from the environment, or if they are not present in the environment select the default.
BUILD_IMAGE=${BUILD_IMAGE:-"false"}
DEV_ENV_NAME=${DEV_ENV_NAME:-"dev-env"}
DOCKER_IMAGE=${DOCKER_IMAGE:-"nasa-bootstrap"}
DOCKER_REPO=${DOCKER_REPO:-"winterwindsroboticsdocker"}
DOCKER_TAG=${DOCKER_TAG:-"v0.1.1"}
FORCE_RECREATE=${FORCE_RECREATE:-"false"}
GPU=${GPU:-"auto"}
GPU_CARD=${GPU_CARD:-"0"}
LAUNCH=${LAUNCH:-"true"}
NGROK=${NGROK:-"false"}
NGROK_TOKEN=${NGROK_TOKEN:-}
NOVNC_PORT=${NOVNC_PORT:-"8080"}
PULL_IMAGE=${PULL_IMAGE:-"true"}
PUSH_IMAGE=${PUSH_IMAGE:-"false"}
RESOLUTION=${RESOLUTION:-"3840x2160"}
USER_PASSWORD=${USER_PASSWORD:-}
VNC=${VNC:-"true"}
VNC_PASSWORD=${VNC_PASSWORD:-}
VNC_PORT=${VNC_PORT:-"5901"}

# Parse the command-line arguments.
while [[ ${#} -gt 0 ]]; do
  case "${1}" in
    --build)
      BUILD_IMAGE="true"
      shift
      ;;
    --dev-env-name)
      DEV_ENV_NAME="${2}"
      shift 2
      ;;
    --docker-image)
      DOCKER_IMAGE="${2}"
      shift 2
      ;;
    --docker-repo)
      DOCKER_REPO="${2}"
      shift 2
      ;;
    --docker-tag)
      DOCKER_TAG="${2}"
      shift 2
      ;;
    --force-cpu)
      GPU="false"
      shift
      ;;
    --force-gpu)
      GPU="true"
      shift
      ;;
    --force-recreate)
      FORCE_RECREATE="true"
      shift
      ;;
    --gpu-card)
      GPU_CARD="${2}"
      shift 2
      ;;
    --help)
      usage
      exit 0
      ;;
    --use-host-x)
      VNC="false"
      shift
      ;;
    --ngrok)
      NGROK="true"
      shift
      ;;
    --ngrok-token)
      NGROK_TOKEN="${2}"
      shift 2
      ;;
    --no-launch)
      LAUNCH="false"
      shift
      ;;
    --no-pull)
      PULL_IMAGE="false"
      shift
      ;;
    --push)
      PUSH_IMAGE="true"
      shift
      ;;
    --user-password)
      USER_PASSWORD="${2}"
      shift 2
      ;;
    --vnc-password)
      VNC_PASSWORD="${2}"
      shift 2
      ;;
    --novnc-port)
      NOVNC_PORT="${2}"
      shift 2
      ;;
    --vnc-port)
      VNC_PORT="${2}"
      shift 2
      ;;
    --resolution)
      RESOLUTION="${2}"
      shift 2
      ;;
    *)
      echo "Unknown option \"${1}\""
      usage
      exit 1
      ;;
  esac
done
set -x

# Work out of the directory containing this script. This is useful since we refer to the Dockerfile which is assumed to
# be in the same directory as this script.
cd "$(dirname "${0}")"

# Validate command-line arguments.
if [[ "${NGROK}" == "true" && "${VNC}" == "false" ]]; then
  echo "Can't run ngrok without vnc."
  exit 1
fi

if [[ -n "${NGROK_TOKEN}" && "${NGROK}" == "false" ]]; then
  echo "Forcing --ngrok since --ngrok-token was provided."
  NGROK="true"
fi

FULL_IMAGE_NAME="${DOCKER_REPO}/${DOCKER_IMAGE}:${DOCKER_TAG}"

# Determine all of the docker options from the environment variables.
DOCKER_OPTIONS=(--detach
                --name "${DEV_ENV_NAME}"
                --hostname "${DEV_ENV_NAME}"
                --env "USER_PASSWORD=${USER_PASSWORD}"
                --volume "$(pwd)/..:/home/wwr/src:rw")

if [[ "${VNC}" == "true" ]]; then
  DOCKER_OPTIONS+=(--env "VNC_PASSWORD=${VNC_PASSWORD}"
                   --env "DISPLAY_GEOMETRY=${RESOLUTION}")
  [[ -n "${VNC_PORT}"   ]] && DOCKER_OPTIONS+=(--publish "${VNC_PORT}:5901")
  [[ -n "${NOVNC_PORT}" ]] && DOCKER_OPTIONS+=(--publish "${NOVNC_PORT}:8080")
else
  touch /tmp/.docker.xauth
  xauth nlist "${DISPLAY}" | sed -e 's/^..../ffff/' | xauth -f /tmp/.docker.xauth nmerge -
  xhost +local:
  DOCKER_OPTIONS+=(--volume "/tmp/.docker.xauth:/tmp/.docker.xauth:rw"
                   --volume "/tmp/.X11-unix:/tmp/.X11-unix:rw"
                   --env "USE_VNC=false"
                   --env "XAUTHORITY=/tmp/.docker.xauth"
                   --env "DISPLAY=${DISPLAY}")
fi

# Try to detect a GPU, if requested.
if [[ "${GPU}" == "auto" ]]; then
  nvidia-smi --list-gpus && GPU="true" || GPU="false"
fi

# If there's a GPU and we're running a VNC server, we need to know the group numbers of some dev entries.
if [[ "${GPU}" == "true" && "${VNC}" == "true" ]]; then
  CARD_GROUP=$(stat --format=%g $(ls /dev/dri/card* | head -1))
  RENDER_GROUP=$(stat --format=%g $(ls /dev/dri/render* | head -1) || printf '')
  if [[ -z "${CARD_GROUP}" || -z "${RENDER_GROUP}" ]]; then
    echo
    echo "!!! Unable to get group info for GPU files in /dev/dri. Disabling GPU support !!!"
    echo
    GPU="false"
  else
    DOCKER_OPTIONS+=(--env "CARD_GROUP=${CARD_GROUP}"
                     --env "RENDER_GROUP=${RENDER_GROUP}"
                     --env "GPU_CARD=${GPU_CARD}")
  fi
fi

[[ "${GPU}" == "true" ]] && DOCKER_OPTIONS+=(--gpus all --device /dev/dri)

# It is possible to compile Mesa 3D with software rendering support from source and get it to be used, but this use case
# is the least desirable anyway. If you don't have GPU support then use the VNC server. If the use-case becomes
# desirable for some reason we can revisit, but will likely run into graphics driver conflicts.
if [[ "${GPU}" == "false" && "${VNC}" == "false" ]]; then
  echo
  echo "!!! ERROR Cannot use host X server without a GPU !!!"
  echo
  exit 1
fi

# Add ngrok options.
DOCKER_OPTIONS+=(--env "USE_NGROK=${NGROK}"
                 --env "NGROK_TOKEN=${NGROK_TOKEN}")

# Obtain the image through push and/or build.
[[ "${PULL_IMAGE}"  == "true" ]] && docker pull "${FULL_IMAGE_NAME}"
[[ "${BUILD_IMAGE}" == "true" ]] && docker build . --tag "${FULL_IMAGE_NAME}"

# Push the image if requested. If we do push, then don't run the container since we're just publishing it.
if [[ "${PUSH_IMAGE}" == "true" ]]; then
  docker push "${FULL_IMAGE_NAME}"
  exit 0
fi

# Start up the development environment. If requested, kill any existing environment with the same name first, otherwise,
# check if a development environment container already exists. If one does, and it's exited, then clean it up. If one
# exists, and it is running, then open a shell in the existing container.
if [[ "${FORCE_RECREATE}" == "true" ]]; then
  docker rm --force "${DEV_ENV_NAME}" || true
else
  if docker container inspect "${DEV_ENV_NAME}" > /dev/null 2>&1; then
    set +x
    echo
    STATUS=$(docker container inspect dev-env --format '{{.State.Status}}')
    if [[ "${STATUS}" == "running" ]]; then
      # A running dev-env container already exists with the desired name. Open a new shell in the container.
      echo "Opening a new shell in the already-existing ${DEV_ENV_NAME} container..."
      exec docker exec --interactive --tty --user wwr "${DEV_ENV_NAME}" bash
    else
      echo "A container named ${DEV_ENV_NAME} already exists, but it is in ${STATUS} state..."
      CHOICE=
      until [[ "${CHOICE}" == "n" || "${CHOICE}" == "y" ]]; do
        read -p "Do you want to destroy the existing container? (y/n) " -n 1 -r CHOICE
        echo
      done
      if [[ "${CHOICE}" == "y" ]]; then
        echo "Removing existing container!"
        docker rm --force "${DEV_ENV_NAME}"
      else
        echo "Not removing existing container!"
        exit 1
      fi
    fi
    set -x
  fi
fi
docker run "${DOCKER_OPTIONS[@]}" "${FULL_IMAGE_NAME}"

# If requested, launch a browser to the local VNC session or a shell to the container.
if [[ "${LAUNCH}" == "true" ]]; then
  if [[ "${VNC}" == "true" && -n "${NOVNC_PORT}" ]]; then
    sleep 3
    if [[ "$OSTYPE" == "darwin"* ]]; then
      open "http://localhost:${NOVNC_PORT}"
    else
      if ! type xdg-open; then echo "Error! xdg-open command not found. Unable to launch browser." && exit 1; fi
      xdg-open "http://localhost:${NOVNC_PORT}"
    fi
  elif [[ "${VNC}" == "false" ]]; then
    docker exec --interactive --tty --user wwr "${DEV_ENV_NAME}" bash
  fi
fi
