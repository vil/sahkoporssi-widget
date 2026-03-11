/*
* Copyright (c) 2024-2026. Vili and contributors.
* This source code is subject to the terms of the GNU General Public
* License, version 3.
*/

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid
import org.kde.plasma.components 3.0 as PlasmaComponents

PlasmoidItem {
    id: root

    Plasmoid.title: "Pörssisähkö"

    property string currentPriceStr: "Fetching..."
    preferredRepresentation: compactRepresentation

    ListModel {
        id: priceModel
        ListElement {
            display: "Fetching..."
            isHeader: true
        }
        ListElement {
            display: ""
            isHeader: false
        }
        ListElement {
            display: ""
            isHeader: false
        }
        ListElement {
            display: ""
            isHeader: false
        }
    }

    compactRepresentation: PlasmaComponents.Label {
        id: panelText
        anchors.fill: parent

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

        text: root.currentPriceStr

        Layout.minimumWidth: implicitWidth

        MouseArea {
            hoverEnabled: true
            anchors.fill: parent
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: Item {
        id: representationItem

        // Define the popup size based on the layout's size + padding
        implicitWidth: mainLayout.implicitWidth + Kirigami.Units.largeSpacing
        implicitHeight: mainLayout.implicitHeight + Kirigami.Units.largeSpacing

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            Repeater {
                model: priceModel
                delegate: PlasmaComponents.Label {
                    required property string display
                    required property bool isHeader

                    text: display
                    font.pixelSize: isHeader ? Kirigami.Theme.defaultFont.pixelSize : Kirigami.Theme.smallFont.pixelSize

                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                }
            }

            // Footer Links
            PlasmaComponents.Label {
                text: "<a href='https://api.spot-hinta.fi/html/150/6'>See more prices...</a>"
                onLinkActivated: link => Qt.openUrlExternally(link)
                font.pixelSize: Math.round(Kirigami.Theme.smallFont.pixelSize * 0.9)
                Layout.alignment: Qt.AlignRight
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
            }

            PlasmaComponents.Label {
                text: "<a href='https://vili.dev'>Made by Vili</a> | <a href='https://spot-hinta.fi'>Powered by spot-hinta.fi</a>"
                onLinkActivated: link => Qt.openUrlExternally(link)
                font.pixelSize: Math.round(Kirigami.Theme.smallFont.pixelSize * 0.8)
                Layout.alignment: Qt.AlignRight
                Layout.fillWidth: true
                opacity: 0.7
            }
        }
    }

    Component.onCompleted: call()

    Timer {
        interval: 900000 // 15 minutes
        repeat: true
        running: true
        onTriggered: call()
    }

    function call() {
        for (let i = 0; i <= 3; i++) {
            fetchPrice(i);
        }
    }

    function fetchPrice(hoursOffset) {
        let date = new Date();
        date.setHours(date.getHours() + hoursOffset);

        let API = "https://api.spot-hinta.fi/JustNow";
        if (hoursOffset > 0) {
            API += "?lookForwardHours=" + hoursOffset;
        }

        var request = new XMLHttpRequest();
        request.open("GET", API, true);
        request.onreadystatechange = function () {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.status === 200) {
                    try {
                        var response = JSON.parse(request.responseText);
                        var priceInCents = (response.PriceWithTax * 100).toFixed(2);

                        var displayText = "";

                        if (hoursOffset === 0) {
                            root.currentPriceStr = `${priceInCents} snt/kWh`;
                            displayText = `Currently: ${priceInCents} snt/kWh`;
                        } else {
                            var timeStr = formatDate(date);
                            displayText = `Price at ${timeStr}: ${priceInCents} snt/kWh`;
                        }

                        priceModel.setProperty(hoursOffset, "display", displayText);
                    } catch (e) {
                        console.error("JSON Parse error", e);
                    }
                } else {
                    var errorText = (hoursOffset === 0) ? "Error" : `Error at ${formatDate(date)}`;
                    priceModel.setProperty(hoursOffset, "display", errorText);
                    if (hoursOffset === 0)
                        root.currentPriceStr = "Error";
                }
            }
        };

        request.send();
    }

    function formatDate(date) {
        var hours = date.getHours();
        var formattedHours = ("0" + hours).slice(-2);
        return formattedHours + ":00";
    }
}
