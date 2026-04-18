import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/journey_insights.dart';
import '../../core/pixel_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils.dart';
import '../../models/check_in.dart';
import '../../models/goal.dart';
import '../../providers/check_in_provider.dart';
import '../../providers/goal_provider.dart';
import '../../providers/share_export_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pixel_mood_line_chart.dart';
import '../../widgets/pixel_progress_bar.dart';

class ProgressPage extends StatefulWidget {
  final bool showAppBar;

  const ProgressPage({super.key, this.showAppBar = false});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  int _selectedView = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: widget.showAppBar
          ? AppBar(title: Text(AppStrings.progressPageTitle))
          : null,
      body: SafeArea(
        top: !widget.showAppBar,
        child: Consumer2<GoalProvider, CheckInProvider>(
          builder: (context, goalProvider, checkInProvider, _) {
            final goals = goalProvider.goals;
            final maxStreak = _maxStreak(checkInProvider, goals);
            final badges = buildCollectibleBadges(
              goals: goals,
              checkIns: checkInProvider.checkIns,
              maxStreak: maxStreak,
            );
            final orderedBadges = [
              ...badges.where((b) => b.unlocked),
              ...badges.where((b) => !b.unlocked),
            ];
            final unlockedCount = badges
                .where((badge) => badge.unlocked)
                .length;
            final completedCount = goals
                .where((goal) => goal.status == GoalStatus.completed)
                .length;

            // 缂傚倸鍊搁崐鎼佸磹閹间礁纾归柟闂寸绾惧綊鏌熼梻瀵割槮缁炬儳缍婇弻鐔兼⒒鐎靛壊妲紒鐐劤缂嶅﹪寮婚敐澶婄闁挎繂鎲涢幘缁樼厱闁靛牆鎳庨顓㈡煛鐏炲墽娲存い銏℃礋閺佹劙宕卞▎妯恍氱紓鍌氬€烽悞锕傚礉閺嶎厹鈧啴宕奸妷銉у姦濡炪倖宸婚崑鎾剁磼閻樿尙效鐎规洘娲熷畷锟犳倶缂佹ɑ銇濆┑鈩冩倐閸┾剝鎷呮笟顖涙暏濠电姵顔栭崰妤呪€﹂崼銉ユ槬闁哄稁鍘介崑鍌涚箾閸℃ê鐏╃痪鎹愭闇夐柨婵嗩槹濞懷囨煟韫囧﹥娅婇柡宀嬬磿閳ь剨缍嗛崜娆撳几濞戙垺鐓?CustomScrollView闂傚倸鍊搁崐鎼佸磹閹间礁纾归柟闂寸绾惧綊鏌ｉ幋锝呅撻柛濠傛健閺屻劑寮崼鐔告闂佺顑嗛幐鍓у垝椤撶偐妲堟俊顖濐嚙濞呇囨⒑濞茶骞楅柣鐔叉櫊瀵鎮㈤崨濠勭Ф闂佸憡鎸嗛崨顔筋啅闂備浇顕х€涒晠鎳濇ィ鍏洦瀵奸弶鎳筹箓鏌涢弴銊ョ仩缂佺姵濞婇弻鐔衡偓娑欘焽缁犮儱霉閻橀潧甯堕柍瑙勫灴椤㈡瑥鈻庨悙顒傜Х闂備胶绮幖顐ゆ崲濠靛棭鍤曞┑鐘宠壘鎯熼梺闈涱槶閸ㄦ椽寮埀顒勬⒒娴ｈ櫣銆婇柛鎾寸箞閺佸啴鍩℃担鍕洴楠炲鎮欓悽娈垮晭闂佽瀛╃粙鎺椻€﹂崶顒佸剹閻庯綆鍓涚壕鍏笺亜閺冨洤袚鐎规洖鐬奸埀顒侇問閸犳盯顢氳閸┿儲寰勬繝搴ｅ弳闂佸憡渚楅崹鍗烆熆閹达附鈷掑ù锝囩摂濞兼劙鏌涙惔銏犫枙闁诡喗妞芥俊鎼佸煛娴ｈ櫣宕堕梻浣哥秺閸嬪﹪宕滈敃鈧妴鎺撶節濮橆厾鍘梺鍓插亝缁诲啴宕抽悾宀€纾奸柣妯哄暱椤ュ鏌嶈閸撴繈锝炴径濞掓椽鏁冮崒姘鳖槶闂佺粯鏌ㄩ崵鏍嚀閸喓鈧帒顫濋敐鍛婵犳鍠栭敃銉ヮ渻娴犲宓侀柟閭﹀幗閸庣喖鏌ㄥ┑鍡樺窛闁哄棎鍊栫换婵堝枈濡椿娼戦梺绋款儏閹虫﹢骞冮悿顖ｆЪ缂備礁鍊哥粔褰掔嵁閺嶃劍濯撮柛婵勫労閸氬淇婇悙顏勨偓鏍蓟閵婏附娅犲ù鐘差儐閺咁剚绻濇繝鍌氭灓婵炴挸顭烽弻鏇㈠醇濠靛浂妫″銈冨劚濡鍩為幋锔绘晩闁告繂瀚ч崑鎾澄旀担渚锤闂佸綊妫块悞锕傚疾濠婂牊鈷戞繛鍡樺劤閻忕姴霉?
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 闂傚倸鍊搁崐鎼佸磹閹间礁纾归柟闂寸绾剧懓顪冪€ｎ亝鎹ｉ柣顓炴閵嗘帒顫濋敐鍛闁诲氦顫夊ú锕傚垂鐠鸿櫣鏆︾紒瀣嚦閺冨牆鐒垫い鎺戝绾惧ジ鏌曟繝蹇擃洭缂佲檧鍋撳┑鐘垫暩婵挳宕愮紒妯绘珷闁哄洨濮峰Λ顖炴煙椤栧棗鐬奸崥瀣⒑閸濆嫮鐏遍柛鐘崇墪閻ｅ嘲顭ㄩ崱鈺傂梺姹囧焺閸ㄩ亶鎯勯鐐茶摕闁挎繂顦粻濠氭煕閹邦剙绾ф繛鍫濐煼濮婃椽宕崟顒佹嫳缂備礁顑嗛悧婊呭垝鐠囨祴妲堥柕蹇曞Х椤旀捇姊洪崨濠傚闁轰讲鏅犻弫鍌炴偩瀹€鈧?濠电姷鏁告慨鐑藉极閸涘﹥鍙忛柣鎴濐潟閳ь剙鍊块、娆撴倷椤掑缍楅梻浣告惈濞层垽宕归崷顓烆棜濠电姵纰嶉悡娆撳级閸繂鈷旈柣锝堜含閻ヮ亪骞嗚缁夋椽鏌″畝瀣瘈鐎规洖鐖兼俊鐑藉Ψ瑜岄惀顏堟⒒娴ｄ警鐒炬い鎴濇嚇钘濇い鏍仜閻撴﹢鏌熸潏鍓х暠缁炬儳鍚嬬换婵囩節閸屾稒宕抽梺鍛婃煥閹芥粎妲愰幒妤佸€锋い鎺嗗亾闁告柣鍊栫换娑氭兜妞嬪海鐦堥悗娈垮枛椤兘骞冮姀銈嗘優闁革富鍙忕槐鏌ユ⒒娓氣偓濞佳呮崲閹烘挻鍙忛柣銏犳啞閸婂爼鏌涢鐘插姕闁抽攱鍨圭槐鎾存媴婵埈浜濋幈銊╁炊椤掍胶鍙嗛梺鍝勬储閸斿鏌囬婧惧亾濞堝灝鏋︽い鏇嗗洤鐓″璺好￠悢鍏肩叆閻庯綆鍋呭鎴︽⒒閸屾瑨鍏岀痪顓炵埣瀹曟粌鈹戠€ｃ劉鍋撻崘顓犵杸闁哄倹顑欓崵銈夋⒑闁偛鑻晶瀛樻叏婵犲嫮甯涢柟宄版嚇瀹曘劍绻濋崘銊ュ濠电姷顣藉Σ鍛村磻閸涱厙娑㈠礃閵娧勬闂佽法鍠撴慨瀵哥不椤曗偓閺岋箑螣娓氼垱歇闂佺濮ゅú鏍煘閹达附鍊烽柡澶嬪灩娴犙囨⒑閹肩偛濡兼繝鈧潏鈺佸灊閻犲洦绁村Σ鍫熺箾閸℃小缂併劌顭峰娲偡閻楀牊鍎撶紓浣割槸閻栬壈妫熼梺鎸庢⒒閺咁偆绮绘ィ鍐╃厱婵犲﹤鍟弳鐔兼煕閹烘柨顣奸柕鍥у椤㈡棃宕熼锝嗩啋濠电姷顣介埀顒€纾崺锝団偓瑙勬礀瀹曨剝鐏掗梻浣哥仢椤戝懘顢旈幖浣光拻闁稿本鐟чˇ锕傛煙濞村鍋撻幇浣圭稁閻熸粎澧楃敮妤呭磻閿熺姵鐓忓璺烘濞呭棝鏌涚€Ｑ勬珚闁哄矉缍侀獮瀣晲閸涘懏鎹囬弻娑氣偓锝庡亜婵绱掓潏銊﹀鞍闁瑰嘲鎳忛幈銊╁箣椤撴繄鍑圭紓浣稿€圭敮鐔虹不濞戞ǚ妲堟繛鍡樺灥楠炴姊洪悷鏉挎倯闁伙綆浜畷婵嗩吋閸涱亝顫嶉悷婊勬瀵鎮㈤崗鐓庢疅闂侀潧锛忛崨顖氬辅闂備浇濮よ摫缂佽鐗撳璇差吋婢跺﹣绱堕梺鍛婃处閸撴瑥鈻嶉妶澶嬧拺闁规儼濮ら弫閬嶆偨椤栥倗绡€鐎殿喛顕ч埥澶婎潩椤愶絽濯伴梻浣告啞閹稿棛浠﹂悙顒夊晣闂傚倸鍊风欢姘焽閼姐倕绶ら柦妯侯檧閼板潡寮堕崼姘珕妞ゎ偅娲熼弻鐔兼倻濡儵鎷荤紒鐐劤閸氬骞堥妸銉庢棃鍩€椤掑嫭鍋嬮柟鐗堟緲閻掑灚銇勯幒鍡椾壕闂佽绻戠换鍫ュ春閻愬搫绠ｉ柨鏇楀亾闁诲繐纾埀顒冾潐濞叉牕煤閿曞倸绠熷┑鍌氭啞閸婄敻鏌涢…鎴濅簼缂佽埖鐓￠幃妤€顫濋銏犵ギ闂佺粯渚楅崳锝呯暦閸洦鏁嗗璺侯儐濞呭秹鏌ｉ悢鍝ョ煀闂佸府缍€濡垽姊洪崜鎻掍簽闁哥姴绉堕幑銏ゅ幢濞戞瑧鍘介梺瑙勬緲閸氣偓缂併劌顭烽弻宥堫檨闁稿繑鐟╁畷鎰攽閸℃瑦娈鹃梺纭呮彧缁犳垹绮婚搹顐＄箚闁靛牆鍊告禍楣冩⒑缁嬭儻顫﹂柛鏂跨焷閻忓啴姊洪幐搴ｇ畵闁瑰啿閰ｅ鎼佸Χ婢跺鍘告繛杈剧悼椤牓鍩€椤掆偓閻忔繈锝炶箛鎾佹椽顢斿鍡樻珜闂備線鈧偛鑻晶鎵磼椤旇姤顥堥柟顔炬櫕缁瑧鎹勯…鎺斿耿闂傚倷鐒︾€笛呮崲閸屾娲晝閸屾氨鐛ラ梺瑙勫婢ф鎮″▎鎾村€垫繛鎴炵懐閻掔晫绱撻崒娑樺摵闁哄苯绉烽¨渚€鏌涢幘瀛樼殤闁轰緡鍣ｉ崹鎯х暦閸ャ劍顔曢梻浣虹帛閸ㄥ綊鎮洪弮鍫濇瀬闁搞儺鍓氶悡鐔镐繆椤栨艾鎮戦柡鍡忔櫊閺岋繝宕遍幇顒€濮﹀┑顔硷功缁垶骞忛崨顔剧懝妞ゆ牗绮屾慨濂告⒒娴ｅ憡鎯堥柣妤佺矒瀹曟粓鎮㈡搴㈡濠电偛妫欑敮鍥ㄧ瑜版帗鐓欓柣鎴炆戠亸顓灻瑰鍕垫疁婵﹥妞藉Λ鍐ㄢ槈鏉堛剱銏ゆ⒑閸濆嫭鍣虹紒顔芥崌楠炲啴鍨鹃弬銉︾€婚梺瑙勫劤椤曨參宕㈤悽鐢电＜闁绘劦鍓氱欢鑼偓瑙勬处閸撶喖鎮伴鈧浠嬵敇閻斿搫骞楅梻濠庡亜濞层垽宕曢幎钘夌畺闁兼祴鏅濈壕濂稿级閸稑濡兼繛鎼櫍閺屾盯鍩為幆褌澹曞┑锛勫亼閸婃牜鏁幒鏂哄亾濮樼厧澧撮柣娑卞櫍婵偓闁挎稑瀚鏇㈡⒑閻熼偊鍤熼柛瀣枛楠炲﹪宕ㄧ€涙鍘卞┑鈽嗗灣缁垰鐣风仦鐐弿濠电姴鎳忛鐘电磼椤旂晫鎳呴柟鐟板婵℃瓕顧侀柛鐐跺煐娣囧﹪鎮欓鍕ㄥ亾瑜忛埀顒勬涧閻倸鐣风憴鍕秶闁冲搫鍟伴悞鍧楁倵楠炲灝鍔氭俊顐㈤叄瀹曟垿宕ㄧ€涙鍘遍梺纭呭焽閸斿秹寮惰ぐ鎺撶厵闂佸灝顑嗛妵婵囨叏婵犲啯銇濈€规洏鍔嶇换婵嬪磼濮樺吋缍岄梺鑽ゅ枑缁秴顭垮鈧畷顖涘閺夋垶鐎銈嗘磵閸嬫挸鈹戦埄鍐╁€愰柛鈺嬬節瀹曟帒顭ㄩ崘銊х杽?
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingL,
                      AppTheme.spacingL,
                      AppTheme.spacingL,
                      AppTheme.spacingM,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.progressPageTitle,
                          style: AppTextStyle.h1,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppStrings.progressPageSubtitle,
                          style: AppTextStyle.bodySmall,
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        _OverviewBoard(
                          unlockedCount: unlockedCount,
                          activeCount: goalProvider.activeGoals.length,
                          completedCount: completedCount,
                          maxStreak: maxStreak,
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        _ViewSwitch(
                          selectedView: _selectedView,
                          onChanged: (v) => setState(() => _selectedView = v),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        PixelMoodLineChart(checkIns: checkInProvider.checkIns),
                        if (checkInProvider.checkIns.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spacingM),
                          Consumer<ShareExportProvider>(
                            builder: (context, share, _) =>
                                _AnnualReportSection(
                                  checkIns: checkInProvider.checkIns,
                                  maxStreak: maxStreak,
                                  shareBusy: share.isBusy,
                                ),
                          ),
                        ],
                        const SizedBox(height: AppTheme.spacingM),
                      ],
                    ),
                  ),
                ),

                // 闂傚倸鍊搁崐鎼佸磹閹间礁纾归柟闂寸绾剧懓顪冪€ｎ亝鎹ｉ柣顓炴閵嗘帒顫濋敐鍛闁诲氦顫夊ú锕傚垂鐠鸿櫣鏆︾紒瀣嚦閺冨牆鐒垫い鎺戝绾惧ジ鏌曟繝蹇擃洭缂佲檧鍋撳┑鐘垫暩婵挳宕愮紒妯绘珷闁哄洨濮峰Λ顖炴煙椤栧棗鐬奸崥瀣⒑閸濆嫮鐏遍柛鐘崇墪閻ｅ嘲顭ㄩ崱鈺傂梺姹囧焺閸ㄩ亶鎯勯鐐茶摕闁挎繂顦粻濠氭煕閹邦剙绾ф繛鍫濐煼濮婃椽宕崟顒佹嫳缂備礁顑嗛悧婊呭垝鐠囨祴妲堥柕蹇曞Х椤旀捇姊洪崨濠傚闁轰讲鏅犻弫鍌炴偩瀹€鈧?缂傚倸鍊搁崐鎼佸磹閹间礁纾归柟闂寸绾惧綊鏌熼梻瀵割槮缁惧墽鎳撻—鍐偓锝庝簼閹癸綁鏌ｉ鐐搭棞闁靛棙甯掗～婵嬫晲閸涱剙顥氶梻鍌欐祰椤曟牠宕规导鏉戝珘妞ゆ帒瀚粻顖炴煕濞戝崬鐏犻悗鍨叀閺岋繝宕堕埡浣圭亖闂侀€炲苯澧俊鐐舵椤繐煤椤忓嫮顔囬柟鑹版彧缁插潡鎮鹃棃娑掓斀闁宠棄妫楁禍婵嬫煟閻斿弶娅呴柣锝囧厴閺佹劙宕奸姀銏℃緫婵犵數鍋為崹鍫曟偡瑜斿畷銏ゆ偨閸涘ň鎷婚梺绋挎湰閼归箖鍩€椤掍焦鍊愭い銏″哺椤㈡﹢鍩楅崫鍕枠闁轰礁鍊垮畷婊嗩槾闁?闂傚倸鍊搁崐鎼佸磹閹间礁纾归柟闂寸绾剧懓顪冪€ｎ亝鎹ｉ柣顓炴閵嗘帒顫濋敐鍛闁诲氦顫夊ú锕傚垂鐠鸿櫣鏆︾紒瀣嚦閺冨牆鐒垫い鎺戝绾惧ジ鏌曟繝蹇擃洭缂佲檧鍋撳┑鐘垫暩婵挳宕愮紒妯绘珷闁哄洨濮峰Λ顖炴煙椤栧棗鐬奸崥瀣⒑閸濆嫮鐏遍柛鐘崇墪閻ｅ嘲顭ㄩ崱鈺傂梺姹囧焺閸ㄩ亶鎯勯鐐茶摕闁挎繂顦粻濠氭煕閹邦剙绾ф繛鍫濐煼濮婃椽宕崟顒佹嫳缂備礁顑嗛悧婊呭垝鐠囨祴妲堥柕蹇曞Х椤旀捇姊洪崨濠傚闁轰讲鏅犻弫鍌炴偩瀹€鈧?
                if (goals.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.spacingL,
                        0,
                        AppTheme.spacingL,
                        120,
                      ),
                      child: const EmptyState(
                        title: AppStrings.progressEmptyBadgesTitle,
                        subtitle: AppStrings.progressEmptyBadgesSubtitle,
                      ),
                    ),
                  ),

                // 闂傚倸鍊搁崐鎼佸磹閹间礁纾归柟闂寸绾剧懓顪冪€ｎ亝鎹ｉ柣顓炴閵嗘帒顫濋敐鍛闁诲氦顫夊ú锕傚垂鐠鸿櫣鏆︾紒瀣嚦閺冨牆鐒垫い鎺戝绾惧ジ鏌曟繝蹇擃洭缂佲檧鍋撳┑鐘垫暩婵挳宕愮紒妯绘珷闁哄洨濮峰Λ顖炴煙椤栧棗鐬奸崥瀣⒑閸濆嫮鐏遍柛鐘崇墪閻ｅ嘲顭ㄩ崱鈺傂梺姹囧焺閸ㄩ亶鎯勯鐐茶摕闁挎繂顦粻濠氭煕閹邦剙绾ф繛鍫濐煼濮婃椽宕崟顒佹嫳缂備礁顑嗛悧婊呭垝鐠囨祴妲堥柕蹇曞Х椤旀捇姊洪崨濠傚闁轰讲鏅犻弫鍌炴偩瀹€鈧?闂傚倸鍊搁崐鎼佸磹閹间礁纾归柟闂寸绾剧懓顪冪€ｎ亝鎹ｉ柣顓炴閵嗘帒顫濋敐鍛婵°倗濮烽崑鐐烘偋閻樻眹鈧線寮撮姀鈩冩珖闂侀€炲苯澧撮柟顔兼健椤㈡瑦鎱ㄩ幇顏嗙泿闂備浇顫夊妯绘櫠鎼淬劍鍋╅弶鍫氭櫇绾惧ジ鏌ｅ鈧褔鍩㈤崼銉︾厸鐎光偓閳ь剟宕伴弽顓炵畺鐟滄柨鐣锋總鍛婂亜闁告繂瀚▓銉╂⒒閸屾瑨鍏岀紒顕呭灦楠炴劙鎳￠妶鍡楀簥闂佺鐬奸崑娑㈡偂濮椻偓閺岀喐娼忛崜褏鏆犵紒鐐劤閸氬鎹㈠┑鍥╃瘈闁稿本绋掑畷鎶芥⒑閸涘﹥鈷愰柟顔煎€搁～蹇撁洪鍕祶濡炪倖鎸鹃崰搴♀枔瀹€鍕拺缂備焦顭囨晶顏堟煏閸埄鐒炬い鏇稻缁绘繂顫濋鍌氬Ф闂備礁鎲￠崝鎴﹀礉鎼达絿鐜婚柣鎰劋閻撶喖骞栭幖顓炵仯缂佸娼ч湁婵犲﹤鍟伴崺锝団偓瑙勬礈閺佹悂鍩€椤掑﹦绉甸柛鎾寸〒婢规洟鎸婃竟婵嗙秺閺佹劙宕堕崜浣稿Ъ闂備線鈧偛鑻晶顖炴煙椤旂厧鈧潡鐛崘顓ф▌濡ょ姷鍋為…鍥箯閻樼粯鍤戦柤绋跨仛閸熸椽姊婚崒娆戠獢婵炰匠鍥ｂ偓锕傚醇閵夈儳锛熷銈嗘煥濡插牓鏁愭径濠囧敹闂佺粯鏌ㄦ晶搴ｇ不濮橆剦娓婚柕鍫濇婢ь剛绱掗鍏兼崳闁轰緡鍠栭埥澶愬閿涘嫬骞楁俊鐐€栭崝褏鐚惧澶婄闁稿秶绌﹔List闂傚倸鍊搁崐鎼佸磹閹间礁纾归柟闂寸绾惧綊鏌ｉ幋锝呅撻柛濠傛健閺屻劑寮崼鐔告闂佺顑嗛幐鍓у垝椤撶偐妲堟俊顖濐嚙濞呇囨⒑濞茶骞楅柣鐔叉櫊瀵鎮㈢亸浣圭€婚梻鍕喘椤㈡俺顦查悡銈嗐亜閹垮啯濞囬柍褜鍏涚欢姘嚕閹绢喖顫呴柍鈺佸暞閻濇牠姊绘笟鈧埀顒傚仜閼活垱鏅堕幍顔剧＜閺夊牄鍔屽ù顕€鏌涢埡瀣瘈鐎规洏鍔戦、娆撳箚瑜嶆俊鍥⒒閸屾凹鐓柛瀣鐓ら柕鍫濐樈閺佸嫰鏌涘☉娆愮稇闁绘帒鐏氶妵鍕箳瀹ュ洤濡界紓浣插亾閻庯綆鍠楅悡娆愩亜閺傚灝甯ㄩ柛瀣崌楠炲洦鎷呴悷鎵处闂傚倷绶氶埀顒傚仜閼活垱鏅剁€电硶鍋?
                if (goals.isNotEmpty && _selectedView == 0)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingL,
                      0,
                      AppTheme.spacingL,
                      140,
                    ),
                    sliver: SliverList.separated(
                      itemCount: goals.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppTheme.spacingM),
                      itemBuilder: (context, index) {
                        final goal = goals[index];
                        final streak = checkInProvider.getStreak(goal.id);
                        final totalCheckIns = checkInProvider
                            .getCheckInsForGoal(goal.id)
                            .length;
                        return _JourneyCard(
                          goal: goal,
                          streakDays: streak,
                          totalCheckIns: totalCheckIns,
                        );
                      },
                    ),
                  ),

                // 闂傚倸鍊搁崐鎼佸磹閹间礁纾归柟闂寸绾剧懓顪冪€ｎ亝鎹ｉ柣顓炴閵嗘帒顫濋敐鍛闁诲氦顫夊ú锕傚垂鐠鸿櫣鏆︾紒瀣嚦閺冨牆鐒垫い鎺戝绾惧ジ鏌曟繝蹇擃洭缂佲檧鍋撳┑鐘垫暩婵挳宕愮紒妯绘珷闁哄洨濮峰Λ顖炴煙椤栧棗鐬奸崥瀣⒑閸濆嫮鐏遍柛鐘崇墪閻ｅ嘲顭ㄩ崱鈺傂梺姹囧焺閸ㄩ亶鎯勯鐐茶摕闁挎繂顦粻濠氭煕閹邦剙绾ф繛鍫濐煼濮婃椽宕崟顒佹嫳缂備礁顑嗛悧婊呭垝鐠囨祴妲堥柕蹇曞Х椤旀捇姊洪崨濠傚闁轰讲鏅犻弫鍌炴偩瀹€鈧?闂傚倸鍊搁崐鎼佸磹瀹勬噴褰掑炊椤掑鏅悷婊冮叄閵嗗啴濡烽埡浣侯啇婵炶揪绲块幊鎾诲焵椤掑啫鐓愰柟渚垮妼椤粓宕卞Δ鈧粻濠氭⒑缂佹绠撻柣鏍с偢瀵鈽夐姀鐘靛姶闂佸憡鍔︽禍鏍ｉ崼銉︹拺婵懓娲ら埀顒侇殜瀹曟垿骞樼拠鍙傦箓鏌涢弴銊ョ仩缂佺姵鐩弻娑㈩敃閿濆棛顦ㄥ銈呴缁夌懓顫忛搹鍦煓婵炲棙鍎抽崜鎶芥⒑閸濄儱校闁绘娲熼敐鐐剁疀閹句焦妞介、鏃堝礋椤愩倐鍋撻鐑嗘富闁靛牆妫欑粈鈧梺鐟板暱闁帮絽鐣峰鍫濈闁绘劏鏅滈弬鈧梻浣虹帛閸旀洖顕ｉ崼鏇為棷闁芥ê顦弨鑺ャ亜閺冨倸浜鹃柡鍡忔櫊閺岀喖鐛崹顔句患闂佸疇妫勯ˇ鍨叏閳ь剟鏌ｅΟ鍨敿闁逞屽墮閻忔繈鍩為幋锕€鐓￠柛鈩冾殘娴犫晠姊洪崨濠呭妞ゆ垵顦悾鐑藉箮缁涘鏅╅梺鍛婃寙閸滃啰闂繝鐢靛仩閹活亞寰婇幑鎰╀汗闁告劏鏅濋々鎻捨旈敐鍛殲闁抽攱鍨块弻娑樷槈濮楀牆浼愰梺璇茬箚閺呮粓濡甸崟顖ｆ晣闁绘﹢娼чˉ鍣昬rGrid闂傚倸鍊搁崐鎼佸磹閹间礁纾归柟闂寸绾惧綊鏌ｉ幋锝呅撻柛濠傛健閺屻劑寮崼鐔告闂佺顑嗛幐鍓у垝椤撶偐妲堟俊顖濐嚙濞呇囨⒑濞茶骞楅柣鐔叉櫊瀵鎮㈢亸浣圭€婚梻鍕喘椤㈡俺顦查悡銈嗐亜閹垮啯濞囬柍褜鍏涚欢姘嚕閹绢喖顫呴柍鈺佸暞閻濇牠姊绘笟鈧埀顒傚仜閼活垱鏅堕幍顔剧＜閺夊牄鍔屽ù顕€鏌涢埡瀣瘈鐎规洏鍔戦、娆撳箚瑜嶆俊鍥⒒閸屾凹鐓柛瀣鐓ら柕鍫濐樈閺佸嫰鏌涘☉娆愮稇闁绘帒鐏氶妵鍕箳瀹ュ洤濡界紓浣插亾閻庯綆鍠楅悡娆愩亜閺傚灝甯ㄩ柛瀣崌楠炲洦鎷呴悷鎵处闂傚倷绶氶埀顒傚仜閼活垱鏅剁€电硶鍋?
                if (goals.isNotEmpty && _selectedView == 1)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingL,
                      0,
                      AppTheme.spacingL,
                      140,
                    ),
                    sliver: SliverGrid.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: AppTheme.spacingM,
                            crossAxisSpacing: AppTheme.spacingM,
                            childAspectRatio: 0.72,
                          ),
                      itemCount: orderedBadges.length,
                      itemBuilder: (context, index) {
                        final badge = orderedBadges[index];
                        final accent =
                            AppTheme.rewardPalette[badge.colorIndex %
                                AppTheme.rewardPalette.length];
                        return _BadgeCard(badge: badge, accent: accent);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  int _maxStreak(CheckInProvider checkInProvider, List<Goal> goals) {
    var maxStreak = 0;
    for (final goal in goals) {
      final streak = checkInProvider.getStreak(goal.id);
      if (streak > maxStreak) maxStreak = streak;
    }
    return maxStreak;
  }
}

class _AnnualReportSection extends StatelessWidget {
  final List<CheckIn> checkIns;
  final int maxStreak;
  final bool shareBusy;

  const _AnnualReportSection({
    required this.checkIns,
    required this.maxStreak,
    required this.shareBusy,
  });

  /// 1.0闂?.4 婵犵數濮烽弫鍛婃叏閻戝鈧倿鎸婃竟鈺嬬秮瀹曘劑寮堕幋鐙呯幢闂備浇顫夊畷妯衡枖濞戞碍顐介柕鍫濇偪瑜版帗鍋愮€瑰壊鍠栭崜浼存⒑濮瑰洤鈧倝宕板Δ鍛﹂柛鏇ㄥ灠閸愨偓闂侀潧臎閸滀礁鎮戦梻鍌欑閹碱偊顢栭崒鐐茬；?闂?1.5闂?.4 婵犵數濮烽弫鍛婃叏閻戝鈧倿鎸婃竟鈺嬬秮瀹曘劑寮堕幋鐙呯幢闂備浇顫夊畷妯衡枖濞戞碍顐介柕鍫濇偪瑜版帗鍋愮€瑰壊鍠栭崜浼存⒑濮瑰洤鈧倝宕板Δ鍛﹂柛鏇ㄥ灠閸愨偓濡炪倖鍔戦崹瑙勭珶鐎ｎ剛纾?闂?2.5闂?.4 婵犵數濮烽弫鍛婃叏閻戝鈧倿鎸婃竟鈺嬬秮瀹曘劑寮堕幋鐙呯幢闂備浇顫夊畷妯衡枖濞戞碍顐介柕鍫濇偪瑜版帗鍋愮€瑰壊鍠栭崜浼存⒑濮瑰洤鈧倝宕板Δ鍛﹂柛鏇ㄥ灠閸愨偓濡炪倖鍔戦崹瑙勭珶婢舵劖鈷?闂?3.5闂?.4 婵犵數濮烽弫鍛婃叏閻戝鈧倿鎸婃竟鈺嬬秮瀹曘劑寮堕幋鐙呯幢闂備浇顫夊畷妯衡枖濞戞碍顐介柕鍫濇偪瑜版帗鍋愮€瑰壊鍠栭崜浼存⒑濮瑰洤鈧倝宕板Δ鍛﹂柛鏇ㄥ灠閸愨偓濡炪倖鍔戦崹瑙勭珶鐎ｎ剛纾?闂?4.5闂?.0 婵犵數濮烽弫鍛婃叏閻戝鈧倿鎸婃竟鈺嬬秮瀹曘劑寮堕幋鐙呯幢闂備浇顫夊畷妯衡枖濞戞碍顐介柕鍫濇偪瑜版帗鍋愮€瑰壊鍠栭崜浼存⒑濮瑰洤鈧倝宕抽敐澶婅摕闁哄洨鍠撶弧鈧棅顐㈡处閹尖晛煤椤撶儐娓?
  static String _emojiForMoodAverage(double avg) {
    if (avg < 1.5) return '\uD83D\uDE2B';
    if (avg < 2.5) return '\uD83D\uDE13';
    if (avg < 3.5) return '\uD83D\uDE0C';
    if (avg < 4.5) return '\uD83D\uDE0A';
    return '\uD83E\uDD73';
  }

  String _avgMoodDisplay() {
    final list = checkIns
        .where((c) => c.mood != null)
        .map((c) => c.mood!)
        .toList();
    if (list.isEmpty) return '\u6682\u65e0';
    final sum = list.fold<int>(0, (a, b) => a + b);
    final avg = sum / list.length;
    final one = (avg * 10).round() / 10;
    final em = _emojiForMoodAverage(avg);
    return '${one.toStringAsFixed(1)} $em';
  }

  void _showReportPlaceholderSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXL),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppTheme.spacingL,
          AppTheme.spacingM,
          AppTheme.spacingL,
          AppTheme.spacingL + MediaQuery.paddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              AppStrings.annualReportComingSoon,
              textAlign: TextAlign.center,
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppTheme.spacingL),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(AppStrings.annualReportComingSoonButton),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const PixelIcon(icon: PixelIcons.calendar, size: 20),
              const SizedBox(width: 10),
              Text('\u5e74\u5ea6\u62a5\u544a', style: AppTextStyle.h3),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _ReportStatCell(
                  label: '\u7d2f\u8ba1\u8bb0\u5f55',
                  value: '${checkIns.length}',
                ),
              ),
              Container(width: 1, height: 24, color: AppTheme.border),
              Expanded(
                child: _ReportStatCell(
                  label: '\u6700\u957f\u8fde\u7eed',
                  value: maxStreak == 0 ? '-' : '$maxStreak \u5929',
                ),
              ),
              Container(width: 1, height: 24, color: AppTheme.border),
              Expanded(
                child: _ReportStatCell(
                  label: '\u5e73\u5747\u5fc3\u60c5',
                  value: _avgMoodDisplay(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: shareBusy
                      ? null
                      : () => _showReportPlaceholderSheet(context),
                  child: const Text('\u751f\u6210\u62a5\u544a'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: OutlinedButton(
                  onPressed: shareBusy
                      ? null
                      : () => context
                            .read<ShareExportProvider>()
                            .shareAllCheckInsCsv(context),
                  child: shareBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('\u5bfc\u51fa CSV'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportStatCell extends StatelessWidget {
  final String label;
  final String value;

  const _ReportStatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyle.caption),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.h3,
          ),
        ],
      ),
    );
  }
}

class _OverviewBoard extends StatelessWidget {
  final int unlockedCount;
  final int activeCount;
  final int completedCount;
  final int maxStreak;

  const _OverviewBoard({
    required this.unlockedCount,
    required this.activeCount,
    required this.completedCount,
    required this.maxStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuRaised,
      ),
      child: Row(
        children: [
          Expanded(
            child: _OverviewMetric(
              label: '\u5df2\u70b9\u4eae',
              value: '$unlockedCount',
              icon: PixelIcons.medal,
            ),
          ),
          Expanded(
            child: _OverviewMetric(
              label: '\u8fdb\u884c\u4e2d',
              value: '$activeCount',
              icon: PixelIcons.flag,
            ),
          ),
          Expanded(
            child: _OverviewMetric(
              label: '\u5df2\u5b8c\u6210',
              value: '$completedCount',
              icon: PixelIcons.trophy,
            ),
          ),
          Expanded(
            child: _OverviewMetric(
              label: '\u6700\u957f\u8fde\u7eed',
              value: maxStreak == 0 ? '-' : '$maxStreak',
              icon: PixelIcons.fire,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  final String label;
  final String value;
  final PixelIconData icon;

  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PixelIcon(icon: icon, size: 18),
        const SizedBox(height: 10),
        Text(value, style: AppTextStyle.h3),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyle.caption),
      ],
    );
  }
}

class _ViewSwitch extends StatelessWidget {
  final int selectedView;
  final ValueChanged<int> onChanged;

  const _ViewSwitch({required this.selectedView, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SwitchButton(
              selected: selectedView == 0,
              label: AppStrings.progressViewJourney,
              onTap: () => onChanged(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SwitchButton(
              selected: selectedView == 1,
              label: AppStrings.progressViewBadges,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchButton extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _SwitchButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.primaryMuted,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyle.caption.copyWith(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final Goal goal;
  final int streakDays;
  final int totalCheckIns;

  const _JourneyCard({
    required this.goal,
    required this.streakDays,
    required this.totalCheckIns,
  });

  @override
  Widget build(BuildContext context) {
    final nodes = buildJourneyNodes(
      goal: goal,
      streakDays: streakDays,
      totalCheckIns: totalCheckIns,
    );

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.neuSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: AppTextStyle.h3),
                    const SizedBox(height: 6),
                    Text(goal.category.label, style: AppTextStyle.caption),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMuted,
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Text(
                  AppUtils.progressText(goal.progress),
                  style: AppTextStyle.caption.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              _MiniJourneyStat(
                label: '\u8bb0\u5f55',
                value: '$totalCheckIns \u6b21',
              ),
              const SizedBox(width: AppTheme.spacingM),
              _MiniJourneyStat(
                label: '\u8fde\u7eed',
                value: streakDays == 0
                    ? '\u5c1a\u672a\u5f00\u59cb'
                    : '$streakDays \u5929',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          _JourneyNodeRow(nodes: nodes),
          const SizedBox(height: AppTheme.spacingL),
          PixelProgressBar(
            progress: goal.progress,
            height: 10,
            blockCount: 16,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.surfaceDeep,
          ),
        ],
      ),
    );
  }
}

class _MiniJourneyStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniJourneyStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Text(
        '$label 闂?$value',
        style: AppTextStyle.caption.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _JourneyNodeRow extends StatelessWidget {
  final List<JourneyNode> nodes;

  const _JourneyNodeRow({required this.nodes});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int index = 0; index < nodes.length; index++) ...[
          Expanded(child: _JourneyNodeView(node: nodes[index])),
          if (index < nodes.length - 1)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 18),
                height: 2,
                color: _connectorColor(
                  left: nodes[index].status,
                  right: nodes[index + 1].status,
                ),
              ),
            ),
        ],
      ],
    );
  }

  Color _connectorColor({
    required JourneyNodeStatus left,
    required JourneyNodeStatus right,
  }) {
    if (left == JourneyNodeStatus.complete &&
        right != JourneyNodeStatus.locked) {
      return AppTheme.primary;
    }
    if (left == JourneyNodeStatus.complete) {
      return AppTheme.primary.withValues(alpha: 0.25);
    }
    return AppTheme.surfaceDeep;
  }
}

class _JourneyNodeView extends StatelessWidget {
  final JourneyNode node;

  const _JourneyNodeView({required this.node});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (node.status) {
      JourneyNodeStatus.complete => (
        AppTheme.accentLight,
        AppTheme.accentStrong,
      ),
      JourneyNodeStatus.current => (AppTheme.primary, Colors.white),
      JourneyNodeStatus.locked => (AppTheme.surfaceVariant, AppTheme.textHint),
    };

    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Center(
            child: PixelIcon(icon: node.icon, size: 16, color: foreground),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          node.label,
          style: AppTextStyle.caption.copyWith(
            color: node.status == JourneyNodeStatus.locked
                ? AppTheme.textHint
                : AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          node.caption,
          textAlign: TextAlign.center,
          style: AppTextStyle.caption.copyWith(fontSize: 10),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final CollectibleBadge badge;
  final Color accent;

  const _BadgeCard({required this.badge, required this.accent});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(AppTheme.radiusXL);

    return Container(
      decoration: BoxDecoration(
        color: badge.unlocked ? AppTheme.surface : AppTheme.surfaceVariant,
        borderRadius: borderRadius,
        border: Border.all(color: AppTheme.border),
        boxShadow: badge.unlocked ? AppTheme.neuSubtle : const [],
      ),
      foregroundDecoration: badge.unlocked
          ? null
          : BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.12),
              borderRadius: borderRadius,
            ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: badge.unlocked
                        ? accent.withValues(alpha: 0.14)
                        : AppTheme.surfaceDeep,
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: badge.unlocked ? 1 : 0.38,
                      child: PixelIcon(icon: badge.icon, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  badge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.h3,
                ),
                const SizedBox(height: 8),
                Text(
                  badge.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: badge.unlocked
                        ? AppTheme.textSecondary
                        : AppTheme.textHint,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badge.unlocked
                    ? accent.withValues(alpha: 0.18)
                    : AppTheme.surfaceDeep,
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Text(
                badge.unlocked ? '\u5df2\u89e3\u9501' : '\u5f85\u89e3\u9501',
                style: AppTextStyle.caption.copyWith(
                  color: badge.unlocked ? accent : AppTheme.textHint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
