#!/bin/sh
# (c) Meta Platforms, Inc. and affiliates. Confidential and proprietary.

usage() {
  cat <<EOF
Usage: $0 -i input_path [-o output_path]

Updates the strings files from the Android strings.

OPTIONS:
    -i  Path to the android-sdk repo root.
    -o  Path to the ios-sdk repo root.
EOF
}

AVAILABLE_LOCALES="eu hr_BA en_CM en_BI rw_RW ast en_SZ he_IL ar uz_Arab en_PN as en_NF ks_IN rwk_TZ zh_Hant_TW en_CN gsw_LI ta_IN th_TH es_EA fr_GF ar_001 en_RW tr_TR de_CH ee_TG en_NG fr_TG az fr_SC es_HN en_AG ru_KZ gsw dyo so_ET zh_Hant_MO de_BE nus_SS km_KH my_MM mgh_MZ ee_GH es_EC kw_GB rm_CH en_ME nyn mk_MK bs_Cyrl_BA ar_MR en_BM ms_Arab en_AI gl_ES en_PR ff_CM ne_IN or_IN khq_ML en_MG pt_TL en_LC ta_SG iu_CA jmc_TZ om_ET lv_LV es_US en_PT vai_Latn_LR yue_HK en_NL to_TO cgg_UG ta en_MH zu_ZA shi_Latn_MA brx_IN ar_KM en_AL te chr_US yo_BJ fr_VU pa tg kea ksh_DE sw_CD te_IN fr_RE th ur_IN yo_NG ti guz_KE tk kl_GL ksf_CM mua_CM lag_TZ lb fr_TN es_PA pl_PL to hi_IN dje_NE es_GQ en_BR kok_IN pl fr_GN bem ha ckb lg tr en_PW en_NO nyn_UG sr_Latn_RS gsw_FR pa_Guru he sn_ZW qu_BO lu_CD mgo_CM ps_AF en_BS da ps ln pt hi lo ebu de gu_IN seh en_CX en_ZM fr_HT fr_GP lt lu ln_CD vai_Latn el_GR lv en_KE sbp hr en_CY es_GT twq_NE zh_Hant_HK kln_KE fr_GQ chr hu es_UY fr_CA ms_BN en_NR mer shi es_PE fr_SN bez sw_TZ wae_CH kkj hy teo_KE en_CZ dz_BT teo ar_JO mer_KE khq ln_CF nn_NO en_MO ar_TD dz ses en_BW en_AS ar_IL nnh bo_CN teo_UG hy_AM ln_CG sr_Latn_BA en_MP ksb_TZ ar_SA smn_FI ar_LY en_AT so_KE fr_CD af_NA en_NU es_PH en_KI en_JE lkt en_AU fa_IR uz_Latn_UZ zh_Hans_CN ewo_CM fr_PF ca_IT en_BZ ar_KW pt_GW fr_FR am_ET en_VC fr_DJ fr_CF es_SV en_MS pt_ST ar_SD luy_KE gd_GB de_LI fr_CG ckb_IQ zh_Hans_SG en_MT ha_NE ewo af_ZA os_GE om_KE nl_SR es_ES es_DO ar_IQ fr_CH nnh_CM es_419 en_MU en_US_POSIX yav_CM luo_KE dua_CM et_EE en_IE ak_GH rwk es_CL kea_CV fr_CI ckb_IR fr_BE se en_NZ en_MV en_LR ha_NG en_KN nb_SJ sg sr_Cyrl_RS ru_RU en_ZW sv_AX si ga_IE en_VG ff_MR sk ky_KG agq_CM mzn fr_BF sl en_MW mr_IN az_Latn en_LS de_AT ka naq_NA sn sr_Latn_ME fr_NC so is_IS twq ig_NG sq fo_FO sr tzm ga om en_LT bas_CM se_NO ki nl_BE ar_QA gd sv kk sw es_CO az_Latn_AZ rn_BI or kl ca en_VI km os en_MY kn en_LU fr_SY ar_TN en_JM fr_PM ko fr_NE ce fr_MA gl ru_MD saq_KE ks fr_CM lb_LU gv_IM fr_BI en_LV en_KR es_NI en_GB kw nl_SX dav_KE tr_CY ky en_UG en_TC ar_EG fr_BJ gu es_PR fr_RW sr_Cyrl_BA lrc_IQ gv fr_MC cs bez_TZ es_CR asa_TZ ar_EH fo_DK ms_Arab_BN en_JP sbp_TZ en_IL lt_LT mfe en_GD cy ug_CN ca_FR es_BO fr_BL bn_IN uz_Cyrl_UZ lrc_IR az_Cyrl en_IM sw_KE en_SB pa_Arab ur_PK haw_US ar_SO en_IN fil fr_MF en_WS es_CU ja_JP fy_NL en_SC en_IO pt_PT en_HK en_GG fr_MG de_LU tzm_MA en_SD shi_Tfng ln_AO as_IN en_GH ms_MY ro_RO jgo_CM dua en_UM en_SE kn_IN en_KY vun_TZ kln lrc en_GI ca_ES rof pt_CV kok pt_BR ar_DJ yi_001 fi_FI zh es_PY ar_SS mua sr_Cyrl_ME vai_Vaii_LR en_001 nl_NL en_TK si_LK en_SG sv_SE fr_DZ ca_AD pt_AO vi xog_UG xog en_IS nb seh_MZ ars es_AR sk_SK en_SH ti_ER nd az_Cyrl_AZ zu ne nd_ZW el_CY en_IT nl_BQ da_GL ja rm fr_ML rn en_VU rof_TZ ro ebu_KE ru_KG en_SI sg_CF mfe_MU nl brx bs_Latn fa zgh_MA en_GM shi_Latn en_FI nn en_EE ru yue kam_KE fur vai_Vaii ar_ER rw ti_ET ff luo fa_AF nl_CW en_HR en_FJ fi pt_MO be en_US en_TO en_SK bg ru_BY it_IT ml_IN gsw_CH qu_EC fo sv_FI en_FK nus ta_LK vun sr_Latn es_BZ fr en_SL bm ar_BH guz bn bo ar_SY lo_LA ne_NP uz_Latn be_BY es_IC sr_Latn_XK ar_MA pa_Guru_IN br luy kde_TZ bs fy fur_IT hu_HU ar_AE en_HU sah_RU zh_Hans en_FM sq_AL ko_KP en_150 en_DE ce_RU en_CA hsb_DE fr_MQ en_TR ro_MD es_VE tg_TJ fr_WF mt_MT kab nmg_CM ms_SG en_GR ru_UA fr_MR zh_Hans_MO ff_GN bs_Cyrl sw_UG ko_KR en_DG bo_IN en_CC shi_Tfng_MA lag it_SM os_RU en_TT ms_Arab_MY sq_MK bem_ZM kde ar_OM kk_KZ cgg bas kam wae es_MX sah zh_Hant en_GU fr_MU fr_KM ar_LB en_BA en_TV sr_Cyrl mzn_IR dje kab_DZ fil_PH se_SE vai hr_HR bs_Latn_BA nl_AW dav so_SO ar_PS en_FR uz_Cyrl ff_SN en_BB ki_KE en_TW naq en_SS mg_MG mas_KE en_RO en_PG mgh dyo_SN mas agq bn_BD haw yi nb_NO da_DK en_DK saq ug cy_GB fr_YT jmc ses_ML en_PH de_DE ar_YE bm_ML yo lkt_US uz_Arab_AF jgo sl_SI uk en_CH asa lg_UG qu_PE mgo id_ID en_NA en_GY zgh pt_MZ fr_LU ta_MY mas_TZ en_DM dsb mg en_BE ur fr_GA ka_GE nmg en_TZ eu_ES ar_DZ id so_DJ hsb yav mk pa_Arab_PK ml en_ER ig se_FI mn ksb uz vi_VN ii qu en_PK ee ast_ES mr ms en_ES ha_GH it_CH sq_XK mt en_CK br_FR tk_TM sr_Cyrl_XK ksf en_SX bg_BG en_PL af el cs_CZ fr_TD zh_Hans_HK is ksh my mn_MN en it dsb_DE ii_CN smn iu eo en_ZA en_AD ak en_RU kkj_CM am es et uk_UA"

i18n_is_valid_locale() {
  local LOCALE=$1
  if [ -n "$LOCALE" ]; then
    case "$AVAILABLE_LOCALES" in
    *$LOCALE*) return 0 ;;
    *) return 1 ;;
    esac
  else
    return 1
  fi
}

OUTPUT_DIR="$FB_SDK_ROOT"

while getopts "hi:o:" OPTION; do
  case $OPTION in
  h)
    usage
    exit 0
    ;;
  i)
    INPUT_DIR="$OPTARG"
    ;;
  o)
    OUTPUT_DIR="$OPTARG"
    ;;
  [?])
    usage
    exit 1
    ;;
  esac
done

if [ ! -d "$INPUT_DIR" ]; then
  fb_internal_warning "Invalid input_path"
  usage
  exit 1
fi

if [ ! -d "$OUTPUT_DIR" ]; then
  fb_internal_warning "Invalid output_path"
  usage
  exit 1
fi

iosLocaleForAndroidLocale() {
  ANDROID_LOCALE=$1
  if [ "" = "$ANDROID_LOCALE" ]; then
    echo "en"
  elif [ "-iw" = "$ANDROID_LOCALE" ]; then
    echo ""
  elif [ "-in" = "$ANDROID_LOCALE" ]; then
    echo "id"
  elif [ "-zh-rCN" = "$ANDROID_LOCALE" ]; then
    echo "zh"
  elif [ "-zh-rHK" = "$ANDROID_LOCALE" ]; then
    echo "zh_Hant_HK"
  elif [ "-zh-rTW" = "$ANDROID_LOCALE" ]; then
    echo "zh_Hant_TW"
  else
    echo $ANDROID_LOCALE | sed s/^-// | sed s/-r/_/
  fi
}

convert() {
  ANDROID_LOCALE=$(echo $1 | sed s/^values//)
  IOS_LOCALE=$(iosLocaleForAndroidLocale $ANDROID_LOCALE)
  if i18n_is_valid_locale "$IOS_LOCALE"; then
    ${FB_SDK_INTERNAL_SCRIPT:-$(dirname $0)}/i18n_android_to_ios.py -i "$INPUT_DIR"/accountkit/accountkitsdk/src/main/res/values$ANDROID_LOCALE/strings.xml -a "$INPUT_DIR"/internal/accountkit_ios_strings/res/values$ANDROID_LOCALE/strings.xml -o "$OUTPUT_DIR"/AccountKit/AccountKitStrings.bundle/Resources/$IOS_LOCALE.lproj/AccountKit.strings
  else
    fb_internal_warning "Ignoring invalid Locale. Android: $ANDROID_LOCALE  iOS: $IOS_LOCALE"
  fi
}

fb_internal_title "Copying AccountKit strings from $INPUT_DIR to $OUTPUT_DIR."

INPUT_DIR=$(echo $INPUT_DIR | sed s/\\/$//)
OUTPUT_DIR=$(echo $OUTPUT_DIR | sed s/\\/$//)

for ANDROID_LOCALE in $(ls -d1 "$INPUT_DIR"/accountkit/accountkitsdk/src/main/res/values* | awk -F / '{print $NF}' | awk '$0 ~ /^values(-[a-z]{2,3}(-r[A-Z]{2})?)?$/'); do
  convert $ANDROID_LOCALE
done

# Done
echo "Successfully ran i18n_update.sh"
