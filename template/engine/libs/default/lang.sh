#!/usr/bin/env bash


################################################################################
# Default Lang
################################################################################




# ── Language pack codes ────────────────────────────────────────────────────
#
# 28 website languages map to 25 language-pack codes.
# (e.g., en-US/en-GB share 'en', pt-PT/pt-BR share 'pt', zh-TW/zh-HK share 'zh-hant')
#
#   en-US English (US)	zh-CN 中文 (CN)	   de-DE Deutsch
#   en-GB English (UK)	zh-TW 中文 (TW)	   fr-FR Français
#						 zh-HK 中文 (HK)	   es-ES Español
#   ja-JP 日本語		   ko-KR 한국어		  it-IT Italiano
#   vi-VN Tiếng Việt	  th-TH ภาษาไทย		pt-PT Português
#   ar-SA العربية		  nl-NL Nederlands	  pt-BR Português (Brasil)
#   sv-SE Svenska		  pl-PL Polski		  ru-RU Русский
#   tr-TR Türkçe		   ro-RO Română		  da-DK Dansk
#   uk-UA Українська	   id-ID Bahasa Indonesia
#   fi-FI Suomi			hi-IN हिन्दी		  el-GR Ελληνικά
#
# All verified present in Ubuntu apt repos.
LANG_PACK_CODES="en de es fr it pt ru zh-hans ja zh-hant ko vi th ar nl sv pl tr ro da uk id fi hi el"
_LP=""
for _c in ${LANG_PACK_CODES}; do
	_LP="${_LP} language-pack-${_c} language-pack-${_c}-base language-pack-gnome-${_c} language-pack-gnome-${_c}-base"
done
LANGUAGE_PACKS="${_LP# }"
unset _LP _c

# ── GRUB boot menu locale submenu ──────────────────────────────────────────
#
# 28 entries — one per website language. Rendered under
# "Try and Install in Other Languages ..." on the live ISO boot screen.
# Format: locale_code|Display Label
SUPPORTED_LOCALES="
en_US|English (United States)
en_GB|English (United Kingdom)
zh_CN|Simplified Chinese (China Mainland)
zh_TW|Traditional Chinese (Taiwan)
zh_HK|Traditional Chinese (Hong Kong)
ja_JP|Japanese
ko_KR|Korean
vi_VN|Vietnamese
th_TH|Thai
de_DE|German
fr_FR|French
es_ES|Spanish
ru_RU|Russian
it_IT|Italian
pt_PT|Portuguese
pt_BR|Portuguese (Brazil)
ar_SA|Arabic
nl_NL|Dutch
sv_SE|Swedish
pl_PL|Polish
tr_TR|Turkish
ro_RO|Romanian
da_DK|Danish
uk_UA|Ukrainian
id_ID|Indonesian
fi_FI|Finnish
hi_IN|Hindi
el_GR|Greek
"
