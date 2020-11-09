#!/bin/bash
# createdb.sh
# Script that automates the process of creating databases/users quickly for cPanel via CLI

while getopts ":u: :d: :p:" opt; do
  case $opt in
    u)
      CPUSER=${OPTARG}
      ;;
    d)
      DB_NAME=${OPTARG}
      ;;
    p)
      PW=${OPTARG}
      ;;
  esac
done

# Variable testing to ensure that the script works as intendit
if [[ -z ${CPUSER} || -z ${DB_NAME} ]] ; then
  # Check if mandatory arguments are supplied to the script
  echo "Error: One or more mandatory variables are currently undefined"
  exit 1;
elif [[ -z ${PW} ]] ; then
  # Create a password if no password is specified upon executing the script
  PW=$(head -c 12 /dev/urandom | base64)
fi

# Let the games begin .. and stuff
# Check if the variables contain data to avoid problems
if [[ -n ${CPUSER} || -n ${DB_NAME} || -n ${PW} ]] ; then
  # Test if the cPanel user exists before proceeding
  if id ${CPUSER} &> /dev/null; then
    # Create DB user and validate status code
    if [[ $(uapi --user="${CPUSER}" Mysql create_user name="${CPUSER}_${DB_NAME}" password="${PW}" | grep status | awk '{print $2}') = 1 ]]; then
      # Create the database and validate status code
      if [[ $(uapi --user="${CPUSER}" Mysql create_database name="${CPUSER}_${DB_NAME}" | grep status | awk '{print $2}') = 1 ]]; then
        # Grant user all permissions to the created database
        uapi --user="${CPUSER}" Mysql set_privileges_on_database user="${CPUSER}_${DB_NAME}" \
        database="${CPUSER}_${DB_NAME}" \
        privileges="DELETE,UPDATE,CREATE,ALTER,DROP,SELECT,INSERT,DROP,INDEX,EXECUTE" > /dev/null # This command generally never fails
        # Print out the details for the newly created database/user
        printf "Done! The following database have successfully been created\nUser/DB: ${CPUSER}_${DB_NAME}\nPassword: ${PW}\n"
      else
        echo "Error: API reported a failure, could not create database"
        exit 1;
      fi
    else
      echo "Error: API reported a failure, could not create database user"
      exit 1;
    fi
  else
    echo "Error: The specified cPanel user does not exist."
    exit 1
  fi
else
  echo "Error: Pre-checks failed, check supplied arguments."
  exit 1
fi
