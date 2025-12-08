/*
 * Copyright (c) 2024-2025. Vili and contributors.
 * This source code is subject to the terms of the GNU General Public
 * License, version 3. If a copy of the GPL was not distributed with this
 * file, You can obtain one at: https://www.gnu.org/licenses/gpl-3.0.txt
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents

PlasmoidItem {
    id: root

    property string price: "Fetching..."
    property string priceInCents: price
    property string nextPrice1: ""
    property string nextPrice2: ""
    property string nextPrice3: ""

    Plasmoid.title: "Sähköpörssi"

    // Define minimums for the Plasmoid itself
    property int plasmoidMinimumWidth: Kirigami.Units.gridUnit * 5
    property int plasmoidMinimumHeight: Kirigami.Units.gridUnit * 5

    // The PlasmoidItem's size will adapt to its content (fullRepresentation)
    implicitWidth: Math.max(plasmoidMinimumWidth, fullRepresentationItem.implicitWidth)
    implicitHeight: Math.max(plasmoidMinimumHeight, fullRepresentationItem.implicitHeight)

    preferredRepresentation: compactRepresentation

    compactRepresentation: PlasmaComponents.Label {
        id: panelText
        anchors.fill: parent
        text: isNaN(parseFloat(root.priceInCents)) ? root.priceInCents : `⚡ ${root.priceInCents} snt/kWh`

        Layout.minimumWidth: implicitWidth
        MouseArea {
            hoverEnabled: true
            anchors.fill: parent
            onClicked: root.expanded = true
        }
    }

    fullRepresentation: Item {
        id: representationItem

        // Padding around the content column
        readonly property int contentPadding: Kirigami.Units.smallSpacing

        // This Item's implicit size is based on the column plus padding
        implicitWidth: internalColumn.implicitWidth + (contentPadding * 2)
        implicitHeight: internalColumn.implicitHeight + (contentPadding * 2)

        Column {
            id: internalColumn
            x: representationItem.contentPadding // Apply padding by positioning
            y: representationItem.contentPadding // Apply padding by positioning
            // The Column's width will be its implicit width (based on widest child)
            // Spacing between labels
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents.Label {
                text: root.price
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                horizontalAlignment: Text.AlignLeft
                Layout.fillWidth: true // Fills the width provided by internalColumn
            }
            PlasmaComponents.Label {
                text: root.nextPrice1
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                horizontalAlignment: Text.AlignLeft
                Layout.fillWidth: true
            }
            PlasmaComponents.Label {
                text: root.nextPrice2
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                horizontalAlignment: Text.AlignLeft
                Layout.fillWidth: true
            }
            PlasmaComponents.Label {
                text: root.nextPrice3
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                horizontalAlignment: Text.AlignLeft
                Layout.fillWidth: true
            }
            PlasmaComponents.Label {
                text: "<a href='https://api.spot-hinta.fi/html/150/6'>See more prices...</a>"
                onLinkActivated: link => Qt.openUrlExternally(link)
                font.pixelSize: Math.round(Kirigami.Theme.smallFont.pixelSize * 0.9)
                elide: Text.ElideLeft
                horizontalAlignment: Text.AlignRight
                Layout.fillWidth: true
            }
            PlasmaComponents.Label {
                text: "<a href='https://vili.dev'>Made by Vili</a> | <a href='https://spot-hinta.fi'>Powered by spot-hinta.fi</a>"
                onLinkActivated: link => Qt.openUrlExternally(link)
                font.pixelSize: Math.round(Kirigami.Theme.smallFont.pixelSize * 0.8)
                elide: Text.ElideLeft
                horizontalAlignment: Text.AlignRight
                Layout.fillWidth: true
            }
        }
    }

    // Update once the root is opened.
    Component.onCompleted: {
        call();
    }

    // Keep updating...
    Timer {
        interval: 900000 // 15 minutes
        repeat: true
        running: true
        onTriggered: call()
    }

    // Gets the current hours price.
    function fetchElectricityPriceNow() {
        var apiUrl = "https://api.spot-hinta.fi/JustNow";
        var request = new XMLHttpRequest();
        request.open("GET", apiUrl, true);
        request.onreadystatechange = function () {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.status === 200) {
                    var response = JSON.parse(request.responseText);
                    // Assuming PriceWithTax is in EUR/kWh, converting to snt/kWh
                    var priceInCents = (response.PriceWithTax * 100).toFixed(2);
                    // Update label text based on current locale for number formatting if possible, or use as is.
                    var formattedResponse = `Currently: ${priceInCents} snt/kWh`;
                    root.price = formattedResponse;
                    root.priceInCents = priceInCents;
                } else {
                    console.error("Error fetching electricity price (now):", request.status, request.statusText);
                    root.price = "Error fetching current price!";
                    root.priceInCents = root.price;
                }
            }
        };
        request.send();
    }

    // Get the price of the next hour.
    function fetchElectricityPriceNext(hours) {
        let date = new Date();
        date.setHours(date.getHours() + hours);
        var formattedTime = formatDate(date);
        // The API seems to provide the price for the hour *starting* at the lookForwardHours offset.
        var apiUrl = "https://api.spot-hinta.fi/JustNow?lookForwardHours=" + hours;
        var request = new XMLHttpRequest();

        request.open("GET", apiUrl, true);
        request.onreadystatechange = function () {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.status === 200) {
                    var response = JSON.parse(request.responseText);
                    var priceInCents = (response.PriceWithTax * 100).toFixed(2);
                    var formattedResponse = `Price at ${formattedTime}: ${priceInCents} snt/kWh`;
                    switch (hours) {
                    case 1:
                        root.nextPrice1 = formattedResponse;
                        break;
                    case 2:
                        root.nextPrice2 = formattedResponse;
                        break;
                    case 3:
                        root.nextPrice3 = formattedResponse;
                        break;
                    }
                } else {
                    console.error(`Error fetching electricity price (+${hours}h):`, request.status, request.statusText);
                    var errorMsg = `Error for ${formattedTime}!`;
                    switch (hours) {
                    case 1:
                        root.nextPrice1 = errorMsg;
                        break;
                    case 2:
                        root.nextPrice2 = errorMsg;
                        break;
                    case 3:
                        root.nextPrice3 = errorMsg;
                        break;
                    }
                }
            }
        };
        request.send();
    }

    // Call all fetch functions.
    function call() {
        fetchElectricityPriceNow();
        for (let i = 1; i <= 3; i++) {
            fetchElectricityPriceNext(i);
        }
    }

    // Format date to display in a readable format (e.g., "5 PM")
    function formatDate(date) {
        var hours = date.getHours();
        var ampm = hours >= 12 ? 'PM' : 'AM';
        hours = hours % 12;
        hours = hours ? hours : 12;
        // minutes = minutes < 10 ? '0' + minutes : minutes;
        var strTime = hours + ' ' + ampm;
        return strTime;
    }
}
