import QtQuick 2.15

Rectangle {
    id: root
    color: "#c9cdd1"

    readonly property real s: height / 768

    // Palette (sampled from the background / car)
    readonly property color ink: "#0d1418"
    readonly property color muted: "#5d676d"
    readonly property color accent: "#b3261e"   // brake-caliper red

    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property real ui: 0
    property string errorMessage: ""

    readonly property string exo: "Exo 2"
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

    FontLoader { id: exoMedium; source: "font/Exo2-Medium.ttf" }
    FontLoader { id: exoBold; source: "font/Exo2-Bold.ttf" }
    FontLoader { id: exoHeavy; source: "font/Exo2-ExtraBold.ttf" }

    // Background image: the plain light panel is the left 42.4% of the image.
    readonly property real imgRatio: 1672 / 941
    readonly property real paintedW: Math.max(width, height * imgRatio)
    readonly property real panelEdge: (width - paintedW) / 2 + paintedW * 0.424

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
        NumberAnimation { target: shakeT; property: "x"; to: 12 * s; duration: 50 }
        NumberAnimation { target: shakeT; property: "x"; to: -12 * s; duration: 50 }
        NumberAnimation { target: shakeT; property: "x"; to: 12 * s; duration: 50 }
        NumberAnimation { target: shakeT; property: "x"; to: 0; duration: 50 }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: pwd.forceActiveFocus()
    }

    // ── Top bar ──────────────────────────────────────────────────────────────
    Text {
        id: brand
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 40 * s
        anchors.leftMargin: 56 * s
        text: root.hostLabel
        font.family: root.exo; font.weight: Font.ExtraBold
        font.pixelSize: 26 * s
        color: root.ink
        opacity: root.ui
    }

    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 46 * s
        anchors.rightMargin: 56 * s
        spacing: 32 * s
        opacity: root.ui

        Repeater {
            model: [
                { label: "SLEEP",    act: 0 },
                { label: "REBOOT",   act: 1 },
                { label: "SHUTDOWN", act: 2 }
            ]
            delegate: Item {
                width: lbl.implicitWidth
                height: lbl.implicitHeight + 6 * s
                Text {
                    id: lbl
                    text: modelData.label
                    font.family: root.exo; font.weight: Font.Bold
                    font.pixelSize: 13 * s
                    font.letterSpacing: 2 * s
                    color: ma.containsMouse ? (modelData.act === 2 ? root.accent : root.ink) : root.muted
                    Behavior on color { ColorAnimation { duration: 120 } }
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: ma.containsMouse ? parent.width : 0
                    height: 2 * s
                    color: modelData.act === 2 ? root.accent : root.ink
                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
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

    // ── Left panel content ───────────────────────────────────────────────────
    Column {
        id: panel
        x: 120 * s
        width: Math.min(380 * s, root.panelEdge - 120 * s - 40 * s)
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -10 * s
        spacing: 0
        opacity: root.ui
        transform: Translate { y: (1 - root.ui) * 24 * s }

        // Clock, set like the "HOT ROD" headline
        Item {
            width: parent.width
            height: 124 * s
            Text {
                id: hourText
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(new Date(), "hh")
                font.family: root.exo; font.weight: Font.ExtraBold
                font.pixelSize: 150 * s
                color: root.ink
            }
        }
        Item {
            width: parent.width
            height: 124 * s
            Text {
                id: minText
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(new Date(), "mm")
                font.family: root.exo; font.weight: Font.ExtraBold
                font.pixelSize: 150 * s
                color: root.ink
            }
        }

        Item { width: 1; height: 20 * s }

        Text {
            id: dateText
            text: Qt.formatDate(new Date(), "dddd · MMM d").toUpperCase()
            font.family: root.exo; font.weight: Font.Bold
            font.pixelSize: 20 * s
            font.letterSpacing: 1 * s
            color: root.ink
        }

        Item { width: 1; height: 44 * s }

        // Username (click to switch user)
        Item {
            id: userRow
            width: parent.width
            height: 28 * s

            Text {
                id: userLabel
                anchors.verticalCenter: parent.verticalCenter
                text: ((userHelper.currentItem && userHelper.currentItem.uName) ? userHelper.currentItem.uName : (typeof userModel !== "undefined" ? userModel.lastUser : "") || "USER").toUpperCase()
                font.family: root.exo; font.weight: Font.Bold
                font.pixelSize: 18 * s
                font.letterSpacing: 1.5 * s
                color: userMa.containsMouse ? root.accent : root.ink
                Behavior on color { ColorAnimation { duration: 120 } }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                visible: typeof userModel !== "undefined" && userModel.count > 1
                text: "SWITCH"
                font.family: root.exo; font.weight: Font.Bold
                font.pixelSize: 11 * s
                font.letterSpacing: 2 * s
                color: root.muted
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

        // Password
        Item {
            id: pwdBox
            width: parent.width
            height: 52 * s
            transform: Translate { id: shakeT }

            TextInput {
                id: pwd
                anchors.fill: parent
                anchors.bottomMargin: 2 * s
                font.family: root.exo; font.weight: Font.Medium
                font.pixelSize: 22 * s
                font.letterSpacing: 6 * s
                color: root.ink
                echoMode: TextInput.Password
                passwordCharacter: "•"
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                selectionColor: root.ink
                selectedTextColor: "#ffffff"
                cursorDelegate: Rectangle { width: 2 * s; color: root.accent }

                onAccepted: {
                    if (text !== "") {
                        var u = userHelper.currentItem ? userHelper.currentItem.uLogin : userModel.lastUser;
                        sddm.login(u, text, root.sessionIndex);
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.errorMessage !== "" ? root.errorMessage : "PASSWORD"
                font.family: root.exo; font.weight: Font.Bold
                font.pixelSize: 13 * s
                font.letterSpacing: 3 * s
                color: root.errorMessage !== "" ? root.accent : root.muted
                visible: pwd.text === ""
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 2 * s
                color: root.errorMessage !== "" ? root.accent : (pwd.activeFocus ? root.ink : "#9aa2a8")
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        Item { width: 1; height: 22 * s }

        // Login button
        Rectangle {
            width: parent.width
            height: 54 * s
            radius: 3 * s
            color: loginMa.pressed ? "#000000" : (loginMa.containsMouse ? root.accent : root.ink)
            Behavior on color { ColorAnimation { duration: 150 } }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 22 * s
                anchors.verticalCenter: parent.verticalCenter
                text: "LOG IN"
                font.family: root.exo; font.weight: Font.ExtraBold
                font.pixelSize: 16 * s
                font.letterSpacing: 3 * s
                color: "#ffffff"
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 22 * s + (loginMa.containsMouse ? 0 : 6 * s)
                anchors.verticalCenter: parent.verticalCenter
                text: "→"
                font.family: root.exo; font.weight: Font.Bold
                font.pixelSize: 20 * s
                color: "#ffffff"
                Behavior on anchors.rightMargin { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
            }
            MouseArea {
                id: loginMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: pwd.accepted()
            }
        }
    }

    // ── Bottom: session name (click to cycle desktop sessions) ──
    Item {
        anchors.left: parent.left
        anchors.leftMargin: 120 * s
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 44 * s
        width: sessionText.implicitWidth
        height: sessionText.implicitHeight + 8 * s
        opacity: root.ui

        Text {
            id: sessionText
            text: ((sessionHelper.currentItem && sessionHelper.currentItem.sName) ? sessionHelper.currentItem.sName : "SESSION").toUpperCase()
            font.family: root.exo; font.weight: Font.Bold
            font.pixelSize: 13 * s
            font.letterSpacing: 2 * s
            color: sessionMa.containsMouse ? root.ink : root.muted
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: sessionMa.containsMouse ? parent.width : 0
            height: 2 * s
            color: root.accent
            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
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
