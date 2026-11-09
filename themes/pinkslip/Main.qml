import QtQuick 2.15

Rectangle {
    id: root
    color: "#e0e0e0"

    readonly property real s: height / 768

    // Palette (sampled from the background)
    readonly property color ink: "#111111"
    readonly property color muted: "#7a7a7a"
    readonly property color pink: "#fa2eb3"
    readonly property color plate: "#fbfbfb"

    readonly property string display: "Anton"
    readonly property string face: "Barlow Condensed"

    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property real ui: 0
    property string errorMessage: ""

    // Machine name: greeter-provided -> written by install.sh -> /etc/hostname
    property string hostLabel: resolveHost()
    function resolveHost() {
        var h = "";
        if (typeof sddm !== "undefined" && sddm.hostName) h = sddm.hostName;
        if (!h && typeof config !== "undefined" && config.hostName) h = config.hostName;
        if (!h) {
            try {
                var x = new XMLHttpRequest();
                x.open("GET", "file:///etc/hostname", false);
                x.send();
                h = (x.responseText || "").trim();
            } catch (e) {}
        }
        return (h || "LOCALHOST").toUpperCase();
    }

    FontLoader { source: "font/Anton-Regular.ttf" }
    FontLoader { source: "font/BarlowCondensed-Medium.ttf" }
    FontLoader { source: "font/BarlowCondensed-SemiBold.ttf" }
    FontLoader { source: "font/BarlowCondensed-Bold.ttf" }

    // Background: the open grey area is the left ~41% of the image.
    readonly property real imgRatio: 1672 / 940
    readonly property real paintedW: Math.max(width, height * imgRatio)
    readonly property real panelEdge: (width - paintedW) / 2 + paintedW * 0.41
    readonly property real contentX: 112 * s
    readonly property real contentW: Math.min(400 * s, panelEdge - contentX - 36 * s)

    Image {
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    // Helpers for current user / session names
    ListView {
        id: sessionHelper
        model: typeof sessionModel !== "undefined" ? sessionModel : null
        currentIndex: root.sessionIndex
        opacity: 0; width: 1; height: 1; z: -100
        delegate: Item { property string sName: model.name || "" }
    }
    ListView {
        id: userHelper
        model: typeof userModel !== "undefined" ? userModel : null
        currentIndex: root.userIndex
        opacity: 0; width: 1; height: 1; z: -100
        delegate: Item {
            property string uName: model.realName || model.name || ""
            property string uLogin: model.name || ""
        }
    }

    Timer { interval: 300; running: true; onTriggered: pwd.forceActiveFocus() }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginFailed() {
            root.errorMessage = "ACCESS DENIED";
            pwd.text = "";
            shakeAnim.start();
            errTimer.start();
        }
    }
    Timer { id: errTimer; interval: 3000; onTriggered: root.errorMessage = "" }

    Component.onCompleted: {
        fadeAnim.start();
        if (typeof keyboard !== "undefined") keyboard.numLock = true;
    }

    NumberAnimation { id: fadeAnim; target: root; property: "ui"; from: 0; to: 1; duration: 800; easing.type: Easing.OutCubic }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: shakeT; property: "x"; to: 14 * s; duration: 50 }
        NumberAnimation { target: shakeT; property: "x"; to: -14 * s; duration: 50 }
        NumberAnimation { target: shakeT; property: "x"; to: 14 * s; duration: 50 }
        NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 50 }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: pwd.forceActiveFocus()
    }

    // ── Top-left: hostname as a black sticker ────────────────────────────────
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 40 * s
        anchors.leftMargin: 56 * s
        width: hostText.implicitWidth + 28 * s
        height: 40 * s
        radius: 4 * s
        color: root.ink
        rotation: -2
        opacity: root.ui
        Text {
            id: hostText
            anchors.centerIn: parent
            text: root.hostLabel
            font.family: root.display
            font.pixelSize: 22 * s
            font.letterSpacing: 2 * s
            color: "#ffffff"
        }
    }

    // ── Top-right: system actions as outlined pills ──────────────────────────
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 42 * s
        anchors.rightMargin: 56 * s
        spacing: 10 * s
        opacity: root.ui

        Repeater {
            model: [
                { label: "SLEEP",    act: 0 },
                { label: "REBOOT",   act: 1 },
                { label: "SHUTDOWN", act: 2 }
            ]
            delegate: Rectangle {
                width: lbl.implicitWidth + 32 * s
                height: 36 * s
                radius: height / 2
                color: ma.containsMouse ? root.pink : "transparent"
                border.color: ma.containsMouse ? root.pink : root.ink
                border.width: 2 * s
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    id: lbl
                    anchors.centerIn: parent
                    text: modelData.label
                    font.family: root.face; font.weight: Font.Bold
                    font.pixelSize: 15 * s
                    font.letterSpacing: 2 * s
                    color: ma.containsMouse ? "#ffffff" : root.ink
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.act === 0) sddm.suspend();
                        else if (modelData.act === 1) sddm.reboot();
                        else sddm.powerOff();
                    }
                }
            }
        }
    }

    // ── Left content ─────────────────────────────────────────────────────────
    Column {
        id: panel
        x: root.contentX
        width: root.contentW
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -6 * s
        spacing: 0
        opacity: root.ui
        transform: Translate { y: (1 - root.ui) * 24 * s }

        // Clock: one tall line, pink colon
        Item {
            width: parent.width
            height: 176 * s
            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: 6 * s
                spacing: 4 * s
                Text {
                    id: hourText
                    text: Qt.formatTime(new Date(), "hh")
                    font.family: root.display
                    font.pixelSize: 190 * s
                    color: root.ink
                }
                Text {
                    id: colonText
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -8 * s
                    text: ":"
                    font.family: root.display
                    font.pixelSize: 190 * s
                    color: root.pink
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.25; duration: 500 }
                        NumberAnimation { to: 1.0; duration: 500 }
                    }
                }
                Text {
                    id: minText
                    text: Qt.formatTime(new Date(), "mm")
                    font.family: root.display
                    font.pixelSize: 190 * s
                    color: root.ink
                }
            }
        }

        Item { width: 1; height: 22 * s }

        // Date as a tilted black tag
        Item {
            width: parent.width
            height: 44 * s
            Rectangle {
                width: dateText.implicitWidth + 28 * s
                height: 38 * s
                radius: 4 * s
                color: root.ink
                rotation: -1.5
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    id: dateText
                    anchors.centerIn: parent
                    text: Qt.formatDate(new Date(), "dddd · MMM d").toUpperCase()
                    font.family: root.face; font.weight: Font.Bold
                    font.pixelSize: 20 * s
                    font.letterSpacing: 4 * s
                    color: "#ffffff"
                }
            }
        }

        Item { width: 1; height: 54 * s }

        // Username: pink pill, click to switch user
        Item {
            width: parent.width
            height: 34 * s
            Rectangle {
                id: userPill
                width: userText.implicitWidth + 32 * s
                height: 30 * s
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                color: userMa.pressed ? "#c81d8d" : (userMa.containsMouse ? root.ink : root.pink)
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    id: userText
                    anchors.centerIn: parent
                    text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (typeof userModel !== "undefined" ? userModel.lastUser : "") || "USER").toUpperCase()
                    font.family: root.face; font.weight: Font.Bold
                    font.pixelSize: 17 * s
                    font.letterSpacing: 3 * s
                    color: "#ffffff"
                }
                MouseArea {
                    id: userMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof userModel !== "undefined" && userModel.count > 0)
                            root.userIndex = (root.userIndex + 1) % userModel.count;
                    }
                }
            }
            Text {
                anchors.left: userPill.right
                anchors.leftMargin: 12 * s
                anchors.verticalCenter: parent.verticalCenter
                visible: typeof userModel !== "undefined" && userModel.count > 1
                text: "TAP TO SWITCH"
                font.family: root.face; font.weight: Font.SemiBold
                font.pixelSize: 13 * s
                font.letterSpacing: 2 * s
                color: root.muted
            }
        }

        Item { width: 1; height: 12 * s }

        // The login "licence plate": password field + GO box
        Rectangle {
            id: plate
            width: parent.width
            height: 92 * s
            radius: 12 * s
            color: root.plate
            border.color: root.errorMessage !== "" ? root.pink : root.ink
            border.width: 4 * s
            Behavior on border.color { ColorAnimation { duration: 150 } }
            transform: Translate { id: shakeT }

            // Region box (acts as the submit button)
            Rectangle {
                id: goBox
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 4 * s
                width: 96 * s
                radius: 8 * s
                color: goMa.pressed ? "#000000" : (goMa.containsMouse ? root.pink : root.ink)
                Behavior on color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: "GO"
                    font.family: root.display
                    font.pixelSize: 40 * s
                    font.letterSpacing: 2 * s
                    color: "#ffffff"
                }
                MouseArea {
                    id: goMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: pwd.accepted()
                }
            }

            TextInput {
                id: pwd
                anchors.left: parent.left
                anchors.right: goBox.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: 22 * s
                anchors.rightMargin: 12 * s
                font.family: root.face; font.weight: Font.Bold
                font.pixelSize: 54 * s
                font.letterSpacing: 6 * s
                color: root.ink
                echoMode: TextInput.Password
                passwordCharacter: "•"
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                selectionColor: root.pink
                selectedTextColor: "#ffffff"
                cursorDelegate: Rectangle { width: 3 * s; color: root.pink }

                onAccepted: {
                    if (text !== "") {
                        var u = userHelper.currentItem ? userHelper.currentItem.uLogin : userModel.lastUser;
                        sddm.login(u, text, root.sessionIndex);
                    }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 22 * s
                anchors.verticalCenter: parent.verticalCenter
                text: root.errorMessage !== "" ? root.errorMessage : "PASSWORD"
                font.family: root.face; font.weight: Font.SemiBold
                font.pixelSize: 34 * s
                font.letterSpacing: 5 * s
                color: root.errorMessage !== "" ? root.pink : "#b8b8b8"
                visible: pwd.text === ""
            }
        }
    }

    // ── Bottom-left: session as a pink tag (click to cycle desktop sessions) ──
    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: root.contentX
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 44 * s
        width: sessionText.implicitWidth + 28 * s
        height: 32 * s
        radius: 4 * s
        color: sessionMa.containsMouse ? root.pink : "transparent"
        border.color: sessionMa.containsMouse ? root.pink : root.ink
        border.width: 2 * s
        opacity: root.ui
        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            id: sessionText
            anchors.centerIn: parent
            text: ((sessionHelper.currentItem && sessionHelper.currentItem.sName) ? sessionHelper.currentItem.sName : "SESSION").toUpperCase()
            font.family: root.face; font.weight: Font.Bold
            font.pixelSize: 15 * s
            font.letterSpacing: 2.5 * s
            color: sessionMa.containsMouse ? "#ffffff" : root.ink
        }
        MouseArea {
            id: sessionMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (typeof sessionModel !== "undefined" && sessionModel.count > 0)
                    root.sessionIndex = (root.sessionIndex + 1) % sessionModel.count;
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var d = new Date();
            hourText.text = Qt.formatTime(d, "hh");
            minText.text = Qt.formatTime(d, "mm");
            dateText.text = Qt.formatDate(d, "dddd · MMM d").toUpperCase();
        }
    }
}
