const faviconUrl = 'https://user-images.githubusercontent.com/978899/175840121-bda1b7ba-35b1-40a0-b9af-34eb330a4d46.png';

function main() {
    const icons = document.querySelectorAll("link[rel~='icon']");
    const defaultIcon = { type: icons[0].type, href: icons[0].href };

    return setInterval(() => {
        const hasUnreadNotifications = document.querySelector(".mail-status.unread") !== null;

        if (hasUnreadNotifications) {
            icons.forEach((icon) => {
                icon.type = "image/png";
                icon.href = faviconUrl;
            });
        } else {
            icons.forEach((icon) => {
                icon.type = defaultIcon.type;
                icon.href = defaultIcon.href;
            });
        }
    }, 1000*15);
}

const runner = main();
