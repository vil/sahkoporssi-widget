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

    Component.onCompleted: fetchPrices()

    Timer {
        interval: 900000 // 15 minutes
        repeat: true
        running: true
        onTriggered: fetchPrices()
    }

    function fetchPrices() {
        // Defaults to 15m resolution based on Swagger documentation
        let API = "https://api.spot-hinta.fi/Today";

        var request = new XMLHttpRequest();
        request.open("GET", API, true);
        request.onreadystatechange = function () {
            if (request.readyState === XMLHttpRequest.DONE) {
                if (request.status === 200) {
                    try {
                        var response = JSON.parse(request.responseText);

                        // Sort array by date just to be safe
                        response.sort((a, b) => new Date(a.DateTime) - new Date(b.DateTime));

                        var now = new Date();
                        var currentIndex = -1;

                        // Find the current 15-minute block
                        for (var i = 0; i < response.length; i++) {
                            var blockTime = new Date(response[i].DateTime);
                            var nextBlockTime = new Date(blockTime.getTime() + 15 * 60000); // Add 15 mins

                            if (now >= blockTime && now < nextBlockTime) {
                                currentIndex = i;
                                break;
                            }
                        }

                        if (currentIndex !== -1) {
                            // Populate the model with current and next 3 blocks
                            for (var j = 0; j < 4; j++) {
                                var dataIndex = currentIndex + j;

                                // Ensure we don't go out of bounds (e.g., late at night without /Tomorrow data)
                                if (dataIndex < response.length) {
                                    var item = response[dataIndex];
                                    var priceInCents = (item.PriceWithTax * 100).toFixed(2);
                                    var apiDate = new Date(item.DateTime);
                                    var timeStr = formatDate(apiDate);
                                    var displayText = "";

                                    if (j === 0) {
                                        root.currentPriceStr = `${priceInCents} snt/kWh`;
                                        displayText = `Currently: ${priceInCents} snt/kWh`;
                                    } else {
                                        displayText = `Price at ${timeStr}: ${priceInCents} snt/kWh`;
                                    }

                                    priceModel.setProperty(j, "display", displayText);
                                } else {
                                    priceModel.setProperty(j, "display", "Data for tomorrow not loaded");
                                }
                            }
                        } else {
                            root.currentPriceStr = "No data for current time";
                            priceModel.setProperty(0, "display", "Could not find current time block");
                        }
                    } catch (e) {
                        console.error("JSON Parse error", e);
                        setErrorState();
                    }
                } else {
                    setErrorState();
                }
            }
        };

        request.send();
    }

    function setErrorState() {
        root.currentPriceStr = "Error";
        priceModel.setProperty(0, "display", "Error fetching data");
        for (var i = 1; i < 4; i++) {
            priceModel.setProperty(i, "display", "");
        }
    }

    function formatDate(date) {
        var hours = ("0" + date.getHours()).slice(-2);
        var minutes = ("0" + date.getMinutes()).slice(-2);
        return hours + ":" + minutes;
    }
}
