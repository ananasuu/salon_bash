#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --no-align --tuples-only -c"

# Funktion zur Anzeige des Service-Menüs und zur Auswahl eines Services
SERVICE_MENU() {
  if [[ $1 ]]; then
    echo -e "\n$1"
  fi

  echo -e "Available Services:"
  SERVICES_LIST=$($PSQL "select service_id, name from services order by service_id")

  # Verarbeitung jeder Zeile in SERVICES_LIST
  while IFS='|' read -r SERVICE_ID NAME
  do
    echo "$SERVICE_ID) $NAME"
  done <<< "$SERVICES_LIST"

  echo -e "\nWhich service do you pick?"
  read SERVICE_ID_SELECTED
  CHECK_SERVICE_ID $SERVICE_ID_SELECTED
}

# Funktion zur Überprüfung der Dienst-ID und zur Planung eines Termins
CHECK_SERVICE_ID() {
  if [[ ! $1 =~ ^[0-9]+$ ]]; then
    # Zurück zum Hauptmenü
    SERVICE_MENU "That is not a valid service number."
  else
    # Überprüfen, ob der Dienst verfügbar ist
    SERVICE_AVAILABILITY=$($PSQL "SELECT name FROM services WHERE service_id = $1")

    # Wenn nicht verfügbar
    if [[ -z $SERVICE_AVAILABILITY ]]; then
      # Zurück zum Hauptmenü
      SERVICE_MENU "That service does not exist."
    else
      # Kundeninformationen abrufen
      echo -e "\nWhat's your phone number?"
      read CUSTOMER_PHONE

      CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

      # Wenn der Kunde nicht existiert
      if [[ -z $CUSTOMER_NAME ]]; then
        # Neuen Kundennamen abrufen
        echo -e "\nWhat's your name?"
        read CUSTOMER_NAME

        # Neuen Kunden einfügen
        INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
      fi

      # Termin planen
      echo -e "\nWhat time would you like your appointment?"
      read SERVICE_TIME

      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
      INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $1, '$SERVICE_TIME')")

      echo -e "\nI have put you down for a $SERVICE_AVAILABILITY at $SERVICE_TIME, $CUSTOMER_NAME."
    fi
  fi
}

# Hauptmenü aufrufen
SERVICE_MENU