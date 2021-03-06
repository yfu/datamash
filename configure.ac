dnl Copyright (C) 2013,2014 Assaf Gordon <assafgordon@gmail.com>
dnl
dnl This file is free software; as a special exception the author gives
dnl unlimited permission to copy and/or distribute it, with or without
dnl modifications, as long as this notice is preserved.
dnl
dnl This program is distributed in the hope that it will be useful, but
dnl WITHOUT ANY WARRANTY, to the extent permitted by law; without even the
dnl implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

AC_INIT([GNU datamash],
        [m4_esyscmd([build-aux/git-version-gen .tarball-version])],
	[assafgordon@gmail.com], [],
	[http://www.gnu.org/software/datamash])

dnl Must come before AM_INIT_AUTOMAKE.
AC_CONFIG_AUX_DIR([build-aux])
AM_INIT_AUTOMAKE([
	1.11.1
	parallel-tests
	subdir-objects
])

# Minimum Autoconf version required.
AC_PREREQ(2.62)

# Where to generate output; srcdir location.
AC_CONFIG_HEADERS([config.h:config.in])dnl Keep filename to 8.3 for MS-DOS.
AC_CONFIG_SRCDIR([src/datamash.c])

dnl Checks for programs.
# We need a C compiler.
AC_PROG_CC
AC_PROG_CC_STDC
AM_PROG_CC_C_O
AC_PROG_CPP

# Since we use gnulib: gl_EARLY must be called as soon as possible after
# the C compiler is checked.  The others could be later, but we just
# keep everything together.
gl_EARLY
gl_INIT

# Add extra compilation warnings. These will only apply to datamash.c not to
# any gnulib modules). See $(WARN_CFLAGS) in Makefile.am
gl_WARN_ADD([-Wall])
gl_WARN_ADD([-Wextra])
gl_WARN_ADD([-Wformat-security])
gl_WARN_ADD([-Wswitch-enum])
gl_WARN_ADD([-Wswitch-default])
gl_WARN_ADD([-Wformat-nonliteral])
gl_WARN_ADD([-Wunused-parameter])
gl_WARN_ADD([-Wfloat-equal])
gl_WARN_ADD([-fdiagnostics-show-option])
gl_WARN_ADD([-funit-at-a-time])
gl_WARN_ADD([-Wmissing-format-attribute])
gl_WARN_ADD([-Wstrict-overflow])
gl_WARN_ADD([-Wsuggest-attribute=const])
gl_WARN_ADD([-Wsuggest-attribute=pure])
AC_SUBST([WARN_CFLAGS])

## Add --enable-werror option to ./configure,
## To enable/disable treating compiler warnings as errors.
## If not specified AND we're compiling from .git repository,
## enable this automatically.
AC_ARG_ENABLE([werror],
  [AS_HELP_STRING([--enable-werror],
     [treat compiler warnings as errors (for developers)])],
  [case $enableval in
     yes|no) ;;
     *)      AC_MSG_ERROR([bad value $enableval for werror option]) ;;
   esac
   werror=$enableval],
   [test -d "$srcdir"/.git \
     && ! test -f "$srcdir"/.tarball-version \
     && werror=yes]
)
if test "$werror" = yes; then
  gl_WARN_ADD([-Werror], [WERROR_CFLAGS])
  AC_SUBST([WERROR_CFLAGS])
fi

## Add --enable-mingw option to ./configure,
## To enable/disable special handling required for Cross-Compiling
## Windows binaries with MingW.
## If the option is not specified, try to auto-detect mingw.
AC_ARG_ENABLE([mingw],
  [AS_HELP_STRING([--enable-mingw],
     [enable options for cross-compilation with mingw])],
  [case $enableval in
     yes|no) ;;
     *)      AC_MSG_ERROR([bad value $enableval for mingw option]) ;;
   esac
   mingw=$enableval],
   [case "$host_os" in
    mingw*) mingw=yes ;;
    *) mingw=no ;;
    esac]
)
if test "x$mingw" = xyes; then
AC_DEFINE([USE_MINGW],[1],
          [Define to 1 if to enable special printf processing under mingw])
MINGW_CFLAGS="-D__USE_MINGW_ANSI_STDIO=1"
AC_SUBST([MINGW_CFLAGS])
AC_MSG_NOTICE([Enabling MingW compilation flags])
fi

## Test for CygWin hosts - these have a broken 'strtold()' implementation:
##  calling strtold("4\t5",NULL) returns "e+9999",
## whereas every other (sane) system returns "4" and stops at the whitespace.
case "$host" in
  *-cygwin) have_broken_strtold=yes ;;
esac
if test "x$have_broken_strtold" = "xyes" ; then
AC_DEFINE([HAVE_BROKEN_STRTOLD],[1],
          [Define to 1 if strtold does not work properly (e.g. in cygwin)])
fi

##
## Check if the system's sort support "-s" (stable) sort.
##  'sort' from GNU Coreutils, FreeBSD, OpenBSD, Busybox support it.
##  DilOS (illumos/opensolaris) does not.
##
if sort -s < /dev/null > /dev/null 2>/dev/null ; then
  AC_DEFINE([HAVE_STABLE_SORT],[1],
            [Define to 1 if sort on this system supports -s for stable sorting])
fi

## Are we building from git checked-out sources?
## (if not, assume it's from a tarball)
## This is used in "Makefile.am" to avoid re-generating the manpage
## when building from tarballs.
AM_CONDITIONAL([BUILD_FROM_GIT], [test -d "$srcdir/.git"])


## Perl is needed for some tests (but not required for building)
## 'PERL_FOUND' is used in Makefile.am to skip some tests.
AC_PATH_PROG([PERL], [perl])
AC_SUBST([PERL])
AM_CONDITIONAL([PERL_FOUND],[test -n "$PERL"])

# i18n support from GNU gettext.
AM_GNU_GETTEXT_VERSION([0.17])
AM_GNU_GETTEXT([external])

AC_CONFIG_FILES([Makefile
  po/Makefile.in
])

AC_OUTPUT

dnl
dnl Report Configuration
dnl
AC_MSG_RESULT([])
AC_MSG_RESULT([ Configuration summary for $PACKAGE])
AC_MSG_RESULT([    version:  $VERSION])
AC_MSG_RESULT([    COMPILER: $CC])
AC_MSG_RESULT([    CFLAGS:   $CFLAGS $WARN_CFLAGS $MINGW_CFLAGS])
AC_MSG_RESULT([    CPPFLAGS: $CPPFLAGS])
AC_MSG_RESULT([    LDFLAGS:  $LDFLAGS])
AC_MSG_RESULT([])
AC_MSG_RESULT([ Default installation directories:])
AC_MSG_RESULT([    program:  ${prefix}/bin/ ])
dnl The default 'datarootdir' is unexpanded, still contains
dnl '${prefix}/share' (note the single quotes in the second parameter).
dnl If it is unexpanded, it means "./configure" will put the default value
dnl in the resulting 'Makefile'.
dnl If it is expanded, it means the user called "./configure" with a custom
dnl "--prefix" parameter.
if test "x$datarootdir" = 'x${prefix}/share' ; then
AC_MSG_RESULT([    examples: ${prefix}/share/${PACKAGE}/examples])
else
AC_MSG_RESULT([    examples: ${datarootdir}/${PACKAGE}/examples])
fi
AC_MSG_RESULT([])
AC_MSG_RESULT([ To change installation path, re-run:])
AC_MSG_RESULT([    ./configure --prefix NEW-PATH])
AC_MSG_RESULT([])
