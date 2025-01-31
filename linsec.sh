#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m' # Reset color

# Function to display the "LinSec" ASCII banner with animation
lin_banner() {
    clear # Clear the screen at the start of each banner display
    
    # Colorized ASCII art
    ascii_art=(
        "${YELLOW}                                                                                                    "
        "                                             @@@@@@@@@@@@@                                          "
        "                                          @@@@@@@@@@@@@@@@@@@                                       "
        "                                        @@@@@@@@@@@@@@@@@@@@@@@                                     "
        "                                       @@@@@@@@@@@@@@@@@@@@@@@@@                                    "
        "                                      @@@@@@@@@@@@@@@@@@@@@@@@@@@                                   "
        "                                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@                                   "
        "                                     @@@@@@@@@@@@@@@@@@@@@@@@@@@@                                   "
        "                                     @@@@@%@@@@@@@@#-..=%@@@@@@@@@                                  "
        "                                     @@@=. .:@@@@@-.    .+@@@@@@@@                                  "
        "                                     @@*.:=:.:@@@=..*%#. .#@@@@@@@                                  "
        "                                     @@=.#@%..%@@:.+@@@+ .*@@@@@@@                                  "
        "                                     @@*.*@@*=----+#@@@= .#@@@@@@@                                  "
        "                                     @@@+-+----------=*+:+@@@@@@@@                                  "
        "                                     @@%*----------------=%@@@@@@@                                  "
        "                                     @@===------------===-*@@@@@@@                                  "
        "                                     @@#=-==-------===---=%@@@@@@@@                                 "
        "                                    @@@@#+=--====-----=+-.-@@@@@@@@@                                "
        "                                    @@@@+..+=------=+..   .*@@@@@@@@@                               "
        "                                   @@@@@.   .:-==-..       .@@@@@@@@@@                              "
        "                                 @@@@@@*                    -@@@@@@@@@@                             "
        "                                @@@@@@%:                    .+@@@@@@@@@@@                           "
        "                               @@@@@@@=.                    .:#@@@@@@@@@@@                          "
        "                              @@@@@@@+..                     .-%@@%@@@@@@@@                         "
        "                            @@@@@@@@#.                        .=@@@##@@@@@@@@                       "
        "                           @@@@%#@@@:                          .+@@@%+@@@@@@@@                      "
        "                          @@@@%*@@@:                            .=@@@@+@@@@@@@@                     "
        "                         @@@@%+@@@-.                             .=@@@@+@@@@@@@@                    "
        "                        @@@@@=@@@+.                               .*@@@#+@@@@@@@                    "
        "                       @@@@@+#@@#:                                 -%@@%=%@@@@@@@                   "
        "                       @@@@%-%@@=.                                 .+@@%-#@@@@@@@                   "
        "                      @@@@@#:%@%.                                   :@@#.#@@@@@@@@                  "
        "                      @@@@@#:#@+.                                   .-=::#@@@@@@@@                  "
        "                     @@@@@@@-:@-                                  .=%@@%#+:-%@@@@@                  "
        "                     @@@@@@@%:..                                 .:@@@@@@@@@*=%@@@                  "
        "                     @@@@@@@@@=..                              .:@@@@@@@@@@@@#*@@@                  "
        "                    @@#-----*@@@+:.                           .=@+=%@@@@@@@@@@%@@@@                 "
        "                   @@*--------#@@@%=..                        :#*--=%@@@@@@#=----*@@                "
        "               @@@%*=----------#@@@@@=..                      -%=----+**+=--------*@@               "
        "             @@*=--------------=%@@@@@@-                     .=%=-----------------=%@               "
        "            @%------------------=%@@@@@@+.                   .+%-------------------*@               "
        "            @#-------------------=%@@@@@@-                   .*#--------------------*@@             "
        "            @@=--------------------#@@@@*.                   .#*---------------------=%@            "
        "            @@=---------------------+%*.                    .-%=----------------------+@@           "
        "            @@=----------------------=#%:                  .+%#----------------------+@@            "
        "           @@*-------------------------*@*:.           ..+%@@@=-------------------*@@@@             "
        "           @@+--------------------------#@@@@#+===+*#@@@@@@@@#----------------=*@@@                 "
        "            @%=-------------------------+@@@@@@@@@@@@@@@@@@@@+--------------+%@@                    "
        "             @@@@@%%##*+=---------------#@@@@@@@@@@@@@@@@@@@@+------------+%@@                      "
        "                    @@@@@@%#*=--------=#@@                  @%=---------=%@@                        "
        "                           @@@@%%###%@@@                     @@*------*%@@                          "
        "                                                               @@@@@@@@                              "
        "                                                                                                    ${RESET}"
        
    )

    # Display the ASCII art line by line
    for line in "${ascii_art[@]}"; do
        echo -e "$line"
        sleep 0.02 # Slight animation delay
    done

    
}
show_banner() {
    clear

    # Existing "LinSec" banner
    banner=(
        " ___         __      _____  ___     ________    _______    ______   "
        "|\"  |       |\" \\    (\"   \\|\"  \\   /\"       )  /\"     \"|  /\" _  \"\\  "
        "||  |       ||  |   |.\\   \\    | (:   \\___/  (: ______) (: ( \\___) "
        "|:  |       |:  |   |: \\   \\  |  \\___  \\     \\/    |    \\/ \\      "
        " \\  |___    |.  |   |.  \\    \\. |   __/  \\\\    // ___)_   //  \\ _   "
        "( \\_|:  \\   /\\  |\\  |    \\    \\ |  /\" \\   :)  (:      \"| (:   _) \\  "
        " \\_______) (__\\_|_)  \\___|\\____\\) (_______/    \\_______)  \\_______) "
    )

    # Display the banner line by line with a delay
    for line in "${banner[@]}"; do
        echo -e "$line"
        sleep 0.05 # Animation delay
    done

    echo -e "${CYAN}==================================================================="
    echo -e "                        Linux Hardening Tool                        "
    echo -e "===================================================================${RESET}"
}

# Goodbye banner displayed upon exit
# Goodbye banner displayed upon exit
show_goodbye() {
    clear
    goodbye_banner=(
        "  _______     ______      ______    ________       _______  ___  ___  _______ "
        " /\" _   \"|   /    \" \\    /    \" \\  |\"      \"\\     |   _  \"\\|\"  \"/  |/\"     \"|    "
        "( : ( \\___)  // ____  \\  // ____  \\ (.  ___  :)    (. |_)  :)\\   \\  /(: ______)   " 
        " \\/ \\      /  /    ) :)/  /    ) :)|: \\   ) ||    |:     \\/  \\\\/  \\/    |    "  
        " //  \\ ___(: (____/ //(: (____/ // (| (___\\ ||    (|  _  \\  /   /   // ___)_  "   
        "( :   _(  _|\\        /  \\        /  |:       :)    |: |_)  :)/   /   (:      \"|  "  
        " \\_______)  \"_____/    \"_____/   (________/     (_______/|___/     \\_______)  "  
    )
    
    echo -e "${RED}"
    for line in "${goodbye_banner[@]}"; do
        echo -e "$line"
        sleep 0.05
    done
    echo -e "${RESET}"
}


# Function to display the menu
show_menu() {
    show_banner # Show the banner at the top
    echo -e "\n${GREEN}========== Main Menu ==========${RESET}"
    echo -e "${BLUE}0.${RESET} ${MAGENTA}Introduction${RESET}"
    echo -e "${BLUE}1.${RESET} ${CYAN}ANSSI Hardware Hardening Script${RESET}"
    echo -e "${BLUE}2.${RESET} ${CYAN}ANSSI Kernel Configuration Hardening Script${RESET}"
    echo -e "${BLUE}3.${RESET} ${CYAN}ANSSI Disk Partition Hardening Script${RESET}"
    echo -e "${BLUE}4.${RESET} ${CYAN}ANSSI Authentication and Identification Hardening Script${RESET}"
    echo -e "${BLUE}5.${RESET} ${CYAN}ANSSI File Protection Hardening Script${RESET}"
    echo -e "${BLUE}6.${RESET} ${CYAN}ANSSI Network Hardening Script${RESET}"    
    echo -e "${BLUE}7.${RESET} ${RED}Exit${RESET}"
    echo -e "${GREEN}==============================${RESET}"
}
lin_banner
# Show the menu initially
show_menu

# Main program loop
while true; do
    # Prompt user for input
    echo -e "\n${YELLOW}Type 'menu' to see the options again or enter a number [0-7]:${RESET}"
    read -p "Your choice: " input




    # Check if the user typed "menu" to display the menu
    if [[ "$input" == "menu" ]]; then
        show_menu
        continue
    fi

    # Execute based on input choice
    case $input in
        0)
            show_banner
            echo -e "\n${MAGENTA}===== Introduction =====${RESET}"
            echo -e "${GREEN}LINUX HARDENING AUTOMATION SCRIPT${RESET}"
            echo -e "${YELLOW}Developed by:${RESET} ZAKARIA OUAHI & ANOUAR BOUKABOUS"
            echo -e "\n${CYAN}This script automates various hardening techniques based on ANSSI "
            echo -e "${CYAN}guidelines to improve the security posture of Linux systems.${RESET}"
            echo -e "${CYAN}Key Features:${RESET}"
            echo -e "- Hardware Hardening"
            echo -e "- Kernel Configuration"
            echo -e "- Disk Partitioning"
            echo -e "- Authentication and Identification"
            echo -e "- File Protection"
            echo -e "- Network Hardening"
            echo -e "\n${GREEN}For more information, please consult the documentation provided with this script.${RESET}"
            ;;
        1)
            show_banner
            echo -e "${YELLOW}Executing: ANSSI Hardware Hardening Script${RESET}"
            read -p "Do you want to execute the bash script? (yes/no): " answer
            if [[ "$answer" == "yes" ]]; then
                echo "Executing the script..."
                sudo ./01.sh
            else
                echo -e "${RED}Script execution canceled. Returning to the main menu.${RESET}"
                sleep 1
                show_menu
                continue
            fi
            ;;
        2)
            show_banner
            echo -e "${YELLOW}Executing: ANSSI Kernel Configuration Hardening Script${RESET}"
            read -p "Do you want to execute the bash script? (yes/no): " answer
            if [[ "$answer" == "yes" ]]; then
                echo "Executing the script..."
                sudo ./02.sh
            else
                echo -e "${RED}Script execution canceled. Returning to the main menu.${RESET}"
                sleep 1               
                show_menu
                continue
            fi
            ;;
        3)
            show_banner
            echo -e "${YELLOW}Executing: ANSSI Disk Partition Hardening Script${RESET}"
            read -p "Do you want to execute the bash script? (yes/no): " answer
            if [[ "$answer" == "yes" ]]; then
                echo "Executing the script..."
                sudo ./03.sh
            else
                echo -e "${RED}Script execution canceled. Returning to the main menu.${RESET}"
                sleep 1
                show_menu
                continue
            fi
            ;;
        4)
            show_banner
            echo -e "${YELLOW}Executing: ANSSI Authentication and Identification Hardening Script${RESET}"
            read -p "Do you want to execute the bash script? (yes/no): " answer
            if [[ "$answer" == "yes" ]]; then
                echo "Executing the script..."
                sudo ./04.sh
            else
                echo -e "${RED}Script execution canceled. Returning to the main menu.${RESET}"
                sleep 1
                show_menu
                continue
            fi
            ;;
        5)
            show_banner
            echo -e "${YELLOW}Executing: ANSSI File Protection Hardening Script${RESET}"
            read -p "Do you want to execute the bash script? (yes/no): " answer
            if [[ "$answer" == "yes" ]]; then
                echo "Executing the script..."
                sudo ./05.sh
            else
                echo -e "${RED}Script execution canceled. Returning to the main menu.${RESET}"
                sleep 1
                show_menu
                continue
            fi
            ;;
        6)
            show_banner
            echo -e "${YELLOW}Executing: ANSSI Network Hardening Script${RESET}"
            read -p "Do you want to execute the bash script? (yes/no): " answer
            if [[ "$answer" == "yes" ]]; then
                echo "Executing the script..."
                sudo ./06.sh
            else
                echo -e "${RED}Script execution canceled. Returning to the main menu.${RESET}"
                sleep 1
                show_menu
                continue
            fi
            ;;
        7)
            show_goodbye
            echo -e "${RED}Exiting...${RESET}"
            exit 0 # This will terminate the script
            ;;
        *)
            show_banner
            echo -e "${RED}Invalid choice. Please enter a number between 0 and 7 or type 'menu' to see options.${RESET}"
            ;;
    esac
done

