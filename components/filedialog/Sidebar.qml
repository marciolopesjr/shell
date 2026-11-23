pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.components.filedialog
import qs.services
import qs.utils

StyledRect {
    id: root

    required property var dialog

    function xdgEntry(location: int, fallback: string, icon: string): var {
        const path = Paths.toLocalFile(StandardPaths.writableLocation(location));
        const prefix = Paths.home + "/";
        const rel = (path && path !== Paths.home && path.startsWith(prefix)) ? path.slice(prefix.length) : fallback;
        const parts = rel.split("/").filter(Boolean);
        return {
            label: parts[parts.length - 1] || fallback,
            cwd: ["Home", ...parts],
            icon
        };
    }

    implicitWidth: Sizes.sidebarWidth
    implicitHeight: inner.implicitHeight + Tokens.padding.medium * 2

    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: inner

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.medium
        spacing: Tokens.spacing.extraSmall

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Tokens.padding.extraSmall / 2
            Layout.bottomMargin: Tokens.spacing.medium
            text: Tr.trCtx("Files", "file dialog sidebar heading")
            color: Colours.palette.m3onSurface
            font: Tokens.font.body.builders.large.weight(Font.Bold).build()
        }

        Repeater {
            model: [
                { label: Tr.tr("Home"), cwd: ["Home"], icon: "home" },
                root.xdgEntry(StandardPaths.DownloadLocation, "Downloads", "file_download"),
                root.xdgEntry(StandardPaths.DesktopLocation, "Desktop", "desktop_windows"),
                root.xdgEntry(StandardPaths.DocumentsLocation, "Documents", "description"),
                root.xdgEntry(StandardPaths.MusicLocation, "Music", "music_note"),
                root.xdgEntry(StandardPaths.PicturesLocation, "Pictures", "image"),
                root.xdgEntry(StandardPaths.MoviesLocation, "Videos", "video_library")
            ]

            StyledRect {
                id: place

                required property var modelData
                readonly property bool selected: root.dialog.cwd.length === modelData.cwd.length && modelData.cwd.every((p, i) => root.dialog.cwd[i] === p)

                Layout.fillWidth: true
                implicitHeight: placeInner.implicitHeight + Tokens.padding.medium * 2

                radius: Tokens.rounding.full
                color: Qt.alpha(Colours.palette.m3secondaryContainer, selected ? 1 : 0)

                StateLayer {
                    color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    onClicked: root.dialog.cwd = place.modelData.cwd.slice()
                }

                RowLayout {
                    id: placeInner

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.large
                    anchors.rightMargin: Tokens.padding.large

                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        text: place.modelData.icon
                        color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        fontStyle: Tokens.font.icon.medium
                        fill: place.selected ? 1 : 0

                        Behavior on fill {
                            Anim {
                                type: Anim.DefaultEffects
                            }
                        }
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: place.modelData.label
                        color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
