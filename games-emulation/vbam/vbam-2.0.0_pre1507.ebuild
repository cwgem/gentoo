# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
WX_GTK_VER="3.0"
CMAKE_MAKEFILE_GENERATOR=emake
inherit cmake-utils wxwidgets flag-o-matic gnome2-utils fdo-mime games

if [[ ${PV} == 9999 ]]; then
	ESVN_REPO_URI="https://svn.code.sf.net/p/vbam/code/trunk"
	inherit subversion
else
	SRC_URI="https://dev.gentoo.org/~radhermit/distfiles/${P}.tar.xz"
	KEYWORDS="amd64 x86"

	# upstream patches
	SRC_URI+=" https://github.com/visualboyadvance-m/visualboyadvance-m/commit/3f3c3859c1c5f92937bef5d3398a37605e9c16ec.patch -> ${PN}-2.0.0_pre1507-ffmpeg3_defines.patch"
	SRC_URI+=" https://github.com/visualboyadvance-m/visualboyadvance-m/commit/029a5fc14b8e5d6f6ce724e66564f9ef89c6a809.patch -> ${PN}-2.0.0_pre1507-ffmpeg3_audio_recording_kludge.patch"
	SRC_URI+=" https://github.com/visualboyadvance-m/visualboyadvance-m/commit/a3a07d2f565756771e9c4f0b9574dcffe51c2fa4.patch -> ${PN}-2.0.0_pre1507-ffmpeg3_encoders_no_s16.patch"
	SRC_URI+=" https://github.com/visualboyadvance-m/visualboyadvance-m/commit/502de18456ee272c4bf264f2db9bea73a6b0bfd0.patch -> ${PN}-2.0.0_pre1507-ffmpeg3_nonfunc_video_encoding.patch"
fi

DESCRIPTION="Game Boy, GBC, and GBA emulator forked from VisualBoyAdvance"
HOMEPAGE="https://sourceforge.net/projects/vbam/"

LICENSE="GPL-2+"
SLOT="0"
IUSE="cairo ffmpeg gtk link lirc nls openal +sdl wxwidgets"
REQUIRED_USE="|| ( sdl gtk wxwidgets )"

RDEPEND=">=media-libs/libpng-1.4:0=
	media-libs/libsdl[sound]
	sys-libs/zlib
	virtual/glu
	virtual/opengl
	link? ( >=media-libs/libsfml-2.0 )
	ffmpeg? ( virtual/ffmpeg[-libav] )
	lirc? ( app-misc/lirc )
	nls? ( virtual/libintl )
	sdl? ( media-libs/libsdl[joystick,opengl] )
	gtk? ( >=dev-cpp/glibmm-2.4.0:2
		>=dev-cpp/gtkmm-2.4.0:2.4
		>=dev-cpp/gtkglextmm-1.2.0 )
	wxwidgets? (
		cairo? ( x11-libs/cairo )
		openal? ( media-libs/openal )
		x11-libs/wxGTK:${WX_GTK_VER}[X,opengl]
	)"
DEPEND="${RDEPEND}
	wxwidgets? ( || (
		media-gfx/imagemagick
		media-gfx/graphicsmagick[imagemagick] ) )
	x86? ( || ( dev-lang/nasm dev-lang/yasm ) )
	nls? ( sys-devel/gettext )
	virtual/pkgconfig"

src_prepare() {
	[[ ${PV} == 9999 ]] && subversion_src_prepare

	# fix issue with zlib-1.2.5.1 macros (bug #383179)
	sed -i '1i#define OF(x) x' src/common/memgzio.c || die

	sed -i "s:\(DESTINATION\) bin:\1 ${GAMES_BINDIR}:" \
		CMakeLists.txt src/{wx,gtk}/CMakeLists.txt || die
	epatch "${FILESDIR}"/${P}-man.patch

	epatch \
		"${DISTDIR}/${P}-ffmpeg3_defines.patch" \
		"${DISTDIR}/${P}-ffmpeg3_audio_recording_kludge.patch" \
		"${DISTDIR}/${P}-ffmpeg3_encoders_no_s16.patch" \
		"${DISTDIR}/${P}-ffmpeg3_nonfunc_video_encoding.patch"
}

src_configure() {
	# Bug #568792
	append-cxxflags -std=c++11 -fpermissive
	local mycmakeargs=(
		$(cmake-utils_use_enable cairo CAIRO)
		$(cmake-utils_use_enable ffmpeg FFMPEG)
		$(cmake-utils_use_enable gtk GTK)
		$(cmake-utils_use_enable link LINK)
		$(cmake-utils_use_enable lirc LIRC)
		$(cmake-utils_use_enable nls NLS)
		$(cmake-utils_use_enable openal OPENAL)
		$(cmake-utils_use_enable sdl SDL)
		$(cmake-utils_use_enable wxwidgets WX)
		$(cmake-utils_use_enable x86 ASM_CORE)
		$(cmake-utils_use_enable x86 ASM_SCALERS)
		-DCMAKE_SKIP_RPATH=ON
		-DDATA_INSTALL_DIR=share/games/${PN}
	)
	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile
}

src_install() {
	cmake-utils_src_install
	use sdl && dodoc doc/ReadMe.SDL.txt
	prepgamesdirs
}

pkg_preinst() {
	[[ ${PV} == 9999 ]] && subversion_pkg_preinst

	games_pkg_preinst
	if use gtk || use wxwidgets ; then
		gnome2_icon_savelist
	fi
}

pkg_postinst() {
	games_pkg_postinst
	if use gtk || use wxwidgets ; then
		gnome2_icon_cache_update
		use gtk && fdo-mime_desktop_database_update
	fi
}

pkg_postrm() {
	if use gtk || use wxwidgets ; then
		gnome2_icon_cache_update
		use gtk && fdo-mime_desktop_database_update
	fi
}
