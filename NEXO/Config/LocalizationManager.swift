import SwiftUI
import Combine

// Global app language enum reused across the app.
// NOTE: This enum is also referenced from SettingsViewModel.
enum AppLanguage: String, CaseIterable {
    case english = "en"
    case french = "fr"
    case arabic = "ar"
}

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    // Current selected language for the whole app
    @Published var language: AppLanguage
    
    // Lightweight key-based translations used across main screens
    // NOTE: This is intentionally small and focused on key UI labels/titles.
    private let translations: [String: [AppLanguage: String]] = [
        // Tab bar titles
        "tab.home": [
            .english: "Home",
            .french: "Accueil",
            .arabic: "الرئيسية"
        ],
        "tab.sessions": [
            .english: "Sessions",
            .french: "Sessions",
            .arabic: "الجلسات"
        ],
        "tab.chat": [
            .english: "Chat",
            .french: "Chat",
            .arabic: "المحادثات"
        ],
        "tab.dashboard": [
            .english: "Dashboard",
            .french: "Tableau de bord",
            .arabic: "لوحة التحكم"
        ],
        
        // Home header
        "home.header.title": [
            .english: "Discover",
            .french: "Découvrir",
            .arabic: "اكتشف"
        ],
        "home.header.subtitle": [
            .english: "Near You",
            .french: "Près de chez vous",
            .arabic: "قريب منك"
        ],
        "home.search.placeholder": [
            .english: "Search activities...",
            .french: "Rechercher des activités...",
            .arabic: "ابحث عن الأنشطة..."
        ],
        "home.loading": [
            .english: "Loading activities...",
            .french: "Chargement des activités...",
            .arabic: "جارٍ تحميل الأنشطة..."
        ],
        "home.empty.title": [
            .english: "No activities found",
            .french: "Aucune activité trouvée",
            .arabic: "لم يتم العثور على أنشطة"
        ],
        "home.empty.subtitle": [
            .english: "Try adjusting your filters or search",
            .french: "Essayez de modifier vos filtres ou votre recherche",
            .arabic: "حاول تغيير عوامل التصفية أو البحث"
        ],
        "home.empty.clearSearch": [
            .english: "Clear Search",
            .french: "Effacer la recherche",
            .arabic: "مسح البحث"
        ],
        "home.empty.clearFilters": [
            .english: "Clear Filters",
            .french: "Réinitialiser les filtres",
            .arabic: "مسح الفلاتر"
        ],
        
        // Home feature cards
        "home.quickMatch.title": [
            .english: "Quick Match",
            .french: "Match rapide",
            .arabic: "تطابق سريع"
        ],
        "home.quickMatch.subtitle": [
            .english: "Swipe to connect",
            .french: "Balayez pour vous connecter",
            .arabic: "اسحب للاتصال"
        ],
        "home.aiMatchmaker.title": [
            .english: "AI Matchmaker",
            .french: "AI Matchmaker",
            .arabic: "مطابقة بالذكاء الاصطناعي"
        ],
        "home.aiMatchmaker.subtitle": [
            .english: "Find partners",
            .french: "Trouver des partenaires",
            .arabic: "اعثر على شركاء"
        ],
        "home.explore.title": [
            .english: "Explore More",
            .french: "Explorer plus",
            .arabic: "استكشف المزيد"
        ],
        "home.explore.subtitle": [
            .english: "Browse sports & discover new people",
            .french: "Parcourez les sports et découvrez de nouvelles personnes",
            .arabic: "تصفح الرياضات واكتشف أشخاصًا جددًا"
        ],
        
        // Map screen header and toggles
        "map.header.title": [
            .english: "Sessions",
            .french: "Sessions",
            .arabic: "الجلسات"
        ],
        "map.header.subtitle": [
            .english: "AI-powered recommendations",
            .french: "Recommandations IA",
            .arabic: "توصيات مدعومة بالذكاء الاصطناعي"
        ],
        "map.toggle.map": [
            .english: "Map",
            .french: "Carte",
            .arabic: "الخريطة"
        ],
        "map.toggle.list": [
            .english: "List",
            .french: "Liste",
            .arabic: "القائمة"
        ],
        "map.loading": [
            .english: "Loading AI suggestions...",
            .french: "Chargement des suggestions IA...",
            .arabic: "جارٍ تحميل اقتراحات الذكاء الاصطناعي..."
        ],
        "map.alert.chooseApp": [
            .english: "Choose Maps App",
            .french: "Choisir une application de cartes",
            .arabic: "اختر تطبيق الخرائط"
        ],
        
        // Profile
        "profile.header.title": [
            .english: "Profile",
            .french: "Profil",
            .arabic: "الملف الشخصي"
        ],
        "profile.stats.joined": [
            .english: "Joined",
            .french: "Rejointes",
            .arabic: "منضم"
        ],
        "profile.stats.hosted": [
            .english: "Hosted",
            .french: "Organisées",
            .arabic: "مستضافة"
        ],
        "profile.stats.rating": [
            .english: "Rating",
            .french: "Note",
            .arabic: "التقييم"
        ],
        "profile.coachDashboard.title": [
            .english: "Coach Dashboard",
            .french: "Tableau coach",
            .arabic: "لوحة المدرب"
        ],
        "profile.coachDashboard.subtitle": [
            .english: "Manage events & track earnings",
            .french: "Gérer les événements et suivre les gains",
            .arabic: "إدارة الجلسات وتتبع الأرباح"
        ],
        "profile.achievements.title": [
            .english: "Achievements",
            .french: "Succès",
            .arabic: "الإنجازات"
        ],
        "profile.achievements.subtitle": [
            .english: "View badges & rewards",
            .french: "Voir badges et récompenses",
            .arabic: "عرض الأوسمة والمكافآت"
        ],
        "profile.tabs.about": [
            .english: "About",
            .french: "À propos",
            .arabic: "حول"
        ],
        "profile.tabs.activities": [
            .english: "Activities",
            .french: "Activités",
            .arabic: "الأنشطة"
        ],
        "profile.tabs.medals": [
            .english: "Medals",
            .french: "Médailles",
            .arabic: "الميداليات"
        ],
        "profile.about.interests": [
            .english: "Interests",
            .french: "Centres d'intérêt",
            .arabic: "الاهتمامات"
        ],
        "profile.about.noInterests": [
            .english: "No interests added yet",
            .french: "Aucun centre d'intérêt ajouté pour le moment",
            .arabic: "لم تتم إضافة اهتمامات بعد"
        ],
        
        // Coach Dashboard
        "coachDashboard.title": [
            .english: "Coach Dashboard",
            .french: "Tableau coach",
            .arabic: "لوحة المدرب"
        ],
        "coachDashboard.totalEarnings": [
            .english: "Total Earnings",
            .french: "Gains totaux",
            .arabic: "إجمالي الأرباح"
        ],
        "coachDashboard.tab.income": [
            .english: "Income",
            .french: "Revenus",
            .arabic: "الدخل"
        ],
        "coachDashboard.tab.feedback": [
            .english: "Feedback",
            .french: "Avis",
            .arabic: "التقييمات"
        ],
        "coachDashboard.legend.daysWithEarnings": [
            .english: "Days with earnings",
            .french: "Jours avec revenus",
            .arabic: "أيام بها أرباح"
        ],
        "coachDashboard.legend.total": [
            .english: "Total:",
            .french: "Total :",
            .arabic: "الإجمالي:"
        ],
        "coachDashboard.averageRatingFormat": [
            .english: "Average rating from %d events",
            .french: "Note moyenne sur %d événements",
            .arabic: "متوسط التقييم من %d جلسات"
        ],
        "coachDashboard.withdraw.title": [
            .english: "Withdraw Funds",
            .french: "Retirer des fonds",
            .arabic: "سحب الأموال"
        ],
        "coachDashboard.withdraw.availableBalanceLabel": [
            .english: "Available Balance:",
            .french: "Solde disponible :",
            .arabic: "الرصيد المتاح:"
        ],
        "coachDashboard.withdraw.balanceCardTitle": [
            .english: "Available Balance",
            .french: "Solde disponible",
            .arabic: "الرصيد المتاح"
        ],
        "coachDashboard.withdraw.amountLabel": [
            .english: "Withdraw Amount",
            .french: "Montant du retrait",
            .arabic: "مبلغ السحب"
        ],
        "coachDashboard.withdraw.amountPlaceholder": [
            .english: "0.00",
            .french: "0,00",
            .arabic: "0.00"
        ],
        "coachDashboard.withdraw.bankLabel": [
            .english: "Bank Account",
            .french: "Compte bancaire",
            .arabic: "الحساب البنكي"
        ],
        "coachDashboard.withdraw.bankPlaceholder": [
            .english: "Enter bank account number",
            .french: "Saisir le numéro de compte bancaire",
            .arabic: "أدخل رقم الحساب البنكي"
        ],
        "coachDashboard.withdraw.withdrawAll": [
            .english: "Withdraw All",
            .french: "Tout retirer",
            .arabic: "سحب الكل"
        ],
        "coachDashboard.withdraw.primaryButton": [
            .english: "Withdraw",
            .french: "Retirer",
            .arabic: "سحب"
        ],
        "coachDashboard.withdraw.bankValidationShort": [
            .english: "Bank account must be at least 10 characters",
            .french: "Le compte bancaire doit contenir au moins 10 caractères",
            .arabic: "يجب أن يكون الحساب البنكي مكونًا من 10 أحرف على الأقل"
        ],
        "coachDashboard.withdraw.historyButton": [
            .english: "Withdraw History",
            .french: "Historique des retraits",
            .arabic: "سجل السحوبات"
        ],
        "coachDashboard.withdraw.historyTitle": [
            .english: "Withdraw History",
            .french: "Historique des retraits",
            .arabic: "سجل السحوبات"
        ],
        "coachDashboard.withdraw.historyEmpty": [
            .english: "No withdrawals yet.",
            .french: "Aucun retrait pour le moment.",
            .arabic: "لا توجد عمليات سحب بعد."
        ],
        "coachDashboard.withdraw.historyAmount": [
            .english: "Amount",
            .french: "Montant",
            .arabic: "المبلغ"
        ],
        "coachDashboard.withdraw.historyStatus": [
            .english: "Recent withdraw requests",
            .french: "Dernières demandes de retrait",
            .arabic: "أحدث طلبات السحب"
        ],
        "coachDashboard.withdraw.historyDate": [
            .english: "Date",
            .french: "Date",
            .arabic: "التاريخ"
        ],
        "coachDashboard.withdraw.status.pending": [
            .english: "Pending",
            .french: "En attente",
            .arabic: "قيد الانتظار"
        ],
        "coachDashboard.withdraw.status.processing": [
            .english: "Processing",
            .french: "En cours",
            .arabic: "جارٍ المعالجة"
        ],
        "coachDashboard.withdraw.status.completed": [
            .english: "Completed",
            .french: "Terminé",
            .arabic: "مكتمل"
        ],
        "coachDashboard.withdraw.status.failed": [
            .english: "Failed",
            .french: "Échoué",
            .arabic: "فشل"
        ],
        
        // Achievements screen
        "achievements.title": [
            .english: "Achievements",
            .french: "Succès",
            .arabic: "الإنجازات"
        ],
        "achievements.loading": [
            .english: "Loading achievements...",
            .french: "Chargement des succès...",
            .arabic: "جارٍ تحميل الإنجازات..."
        ],
        "achievements.stats.yourLevel": [
            .english: "Your Level",
            .french: "Votre niveau",
            .arabic: "مستواك"
        ],
        "achievements.stats.xpProgress": [
            .english: "XP Progress",
            .french: "Progression XP",
            .arabic: "تقدم الخبرة"
        ],
        "achievements.stats.badges": [
            .english: "Badges",
            .french: "Badges",
            .arabic: "الشارات"
        ],
        "achievements.stats.streak": [
            .english: "Streak",
            .french: "Série",
            .arabic: "سلسلة"
        ],
        "achievements.stats.bestStreak": [
            .english: "Best Streak",
            .french: "Meilleure série",
            .arabic: "أفضل سلسلة"
        ],
        "achievements.leaderboard.you": [
            .english: "You",
            .french: "Vous",
            .arabic: "أنت"
        ],
        "achievements.challenge.rewardPrefix": [
            .english: "Reward:",
            .french: "Récompense :",
            .arabic: "المكافأة:"
        ],
        
        // Premium (subscriptions, billing, analytics, notifications)
        "premium.title": [
            .english: "Premium Plans",
            .french: "Offres Premium",
            .arabic: "الخطط المميزة"
        ],
        "premium.hero.title": [
            .english: "Unlock Your Potential",
            .french: "Libérez votre potentiel",
            .arabic: "أطلق إمكاناتك"
        ],
        "premium.hero.subtitle": [
            .english: "Create more activities and grow your coaching business",
            .french: "Créez plus d’activités et développez votre activité de coach",
            .arabic: "أنشئ المزيد من الجلسات وطور نشاطك كمدرب"
        ],
        "premium.hero.currentPrefix": [
            .english: "Current:",
            .french: "Actuel :",
            .arabic: "الخطة الحالية:"
        ],
        "premium.choosePlan.title": [
            .english: "Choose Your Plan",
            .french: "Choisissez votre offre",
            .arabic: "اختر خطتك"
        ],
        "premium.currentPlan.title": [
            .english: "Current Plan",
            .french: "Offre actuelle",
            .arabic: "الخطة الحالية"
        ],
        "premium.stats.usageStatistics": [
            .english: "Usage Statistics",
            .french: "Statistiques d'utilisation",
            .arabic: "إحصائيات الاستخدام"
        ],
        "premium.stats.unlimitedActivities": [
            .english: "Unlimited Activities",
            .french: "Activités illimitées",
            .arabic: "أنشطة غير محدودة"
        ],
        "premium.stats.unlimited": [
            .english: "Unlimited",
            .french: "Illimité",
            .arabic: "غير محدود"
        ],
        "premium.stats.activitiesRemainingFormat": [
            .english: "%d left this month",
            .french: "Il en reste %d ce mois-ci",
            .arabic: "متبقي %d هذا الشهر"
        ],
        "premium.stats.created": [
            .english: "Created",
            .french: "Créées",
            .arabic: "تم إنشاؤها"
        ],
        "premium.stats.planLabel": [
            .english: "Plan",
            .french: "Offre",
            .arabic: "الخطة"
        ],
        "premium.usage.analytics": [
            .english: "Analytics",
            .french: "Analytique",
            .arabic: "التحليلات"
        ],
        "premium.usage.billing": [
            .english: "Billing",
            .french: "Facturation",
            .arabic: "الفوترة"
        ],
        "premium.usage.notifications": [
            .english: "Notifications",
            .french: "Notifications",
            .arabic: "الإشعارات"
        ],
        "premium.alert.successTitle": [
            .english: "Success!",
            .french: "Succès !",
            .arabic: "تم بنجاح!"
        ],
        "premium.alert.successMessage": [
            .english: "Your subscription has been activated successfully!",
            .french: "Votre abonnement a été activé avec succès !",
            .arabic: "تم تفعيل اشتراكك بنجاح!"
        ],
        "premium.billing.title": [
            .english: "Billing Center",
            .french: "Centre de facturation",
            .arabic: "مركز الفوترة"
        ],
        "premium.billing.paymentHistory": [
            .english: "Payment History",
            .french: "Historique des paiements",
            .arabic: "سجل المدفوعات"
        ],
        "premium.billing.noPayments": [
            .english: "No payments yet.",
            .french: "Aucun paiement pour le moment.",
            .arabic: "لا توجد مدفوعات بعد."
        ],
        "premium.billing.totalPaid": [
            .english: "Total Paid",
            .french: "Total payé",
            .arabic: "إجمالي المدفوع"
        ],
        "premium.billing.nextPayment": [
            .english: "Next Payment",
            .french: "Prochain paiement",
            .arabic: "الدفعة القادمة"
        ],
        "premium.billing.status.pending": [
            .english: "Pending",
            .french: "En attente",
            .arabic: "قيد الانتظار"
        ],
        "premium.billing.status.failed": [
            .english: "Failed",
            .french: "Échoué",
            .arabic: "فشل"
        ],
        "premium.billing.status.paid": [
            .english: "Paid",
            .french: "Payé",
            .arabic: "مدفوع"
        ],
        "premium.billing.invoice": [
            .english: "Invoice",
            .french: "Facture",
            .arabic: "فاتورة"
        ],
        "premium.billing.invoiceError": [
            .english: "Could not generate invoice PDF.",
            .french: "Impossible de générer le PDF de la facture.",
            .arabic: "تعذر إنشاء ملف PDF للفاتورة."
        ],
        "premium.notifications.title": [
            .english: "Premium Notifications",
            .french: "Notifications Premium",
            .arabic: "إشعارات بريميوم"
        ],
        "premium.notifications.comingSoonTitle": [
            .english: "Coming Soon",
            .french: "Bientôt disponible",
            .arabic: "قريباً"
        ],
        "premium.notifications.comingSoonDescription": [
            .english: "Premium notifications feature will be available soon. This will include subscription reminders, limit warnings, and payment updates.",
            .french: "La fonctionnalité de notifications Premium sera bientôt disponible. Elle inclura des rappels d'abonnement, des alertes de limite et des mises à jour de paiement.",
            .arabic: "ميزة إشعارات البريميوم ستكون متاحة قريباً، وستتضمن تذكيرات الاشتراك، وتنبيهات الحدود، وتحديثات المدفوعات."
        ],
        "premium.analytics.title": [
            .english: "Premium Analytics",
            .french: "Analytique Premium",
            .arabic: "تحليلات بريميوم"
        ],
        "premium.analytics.stat.totalActivities": [
            .english: "Total Activities",
            .french: "Activités totales",
            .arabic: "إجمالي الأنشطة"
        ],
        "premium.analytics.stat.thisMonth": [
            .english: "This Month",
            .french: "Ce mois-ci",
            .arabic: "هذا الشهر"
        ],
        "premium.analytics.stat.revenue": [
            .english: "Revenue",
            .french: "Revenus",
            .arabic: "الإيرادات"
        ],
        "premium.analytics.stat.fillRate": [
            .english: "Fill Rate",
            .french: "Taux de remplissage",
            .arabic: "نسبة الإشغال"
        ],
        "premium.analytics.statistics.title": [
            .english: "Statistics",
            .french: "Statistiques",
            .arabic: "إحصائيات"
        ],
        "premium.analytics.statistics.avgActivitiesPerMonth": [
            .english: "Average Activities/Month",
            .french: "Activités moyennes/mois",
            .arabic: "متوسط الأنشطة/الشهر"
        ],
        "premium.analytics.statistics.totalParticipants": [
            .english: "Total Participants",
            .french: "Participants totaux",
            .arabic: "إجمالي المشاركين"
        ],
        "premium.analytics.statistics.avgParticipantsPerActivity": [
            .english: "Avg Participants/Activity",
            .french: "Moy. participants/activité",
            .arabic: "متوسط المشاركين/النشاط"
        ],
        "premium.analytics.statistics.avgRevenuePerActivity": [
            .english: "Avg Revenue/Activity",
            .french: "Moy. revenus/activité",
            .arabic: "متوسط الإيرادات/النشاط"
        ],
        "premium.analytics.section.activitiesByMonth": [
            .english: "Activities by Month",
            .french: "Activités par mois",
            .arabic: "الأنشطة حسب الشهر"
        ],
        "premium.analytics.section.topActivities": [
            .english: "Top Activities",
            .french: "Meilleures activités",
            .arabic: "أفضل الأنشطة"
        ],
        
        // Coach Verification (application + status)
        "coachVerification.nav.apply": [
            .english: "Apply for Verification",
            .french: "Demander la vérification",
            .arabic: "طلب التحقق"
        ],
        "coachVerification.nav.status": [
            .english: "Verification Status",
            .french: "Statut de vérification",
            .arabic: "حالة التحقق"
        ],
        "coachVerification.loading.submitting": [
            .english: "Submitting application...",
            .french: "Envoi de la demande...",
            .arabic: "جارٍ إرسال الطلب..."
        ],
        "coachVerification.form.emailLabel": [
            .english: "Email",
            .french: "E-mail",
            .arabic: "البريد الإلكتروني"
        ],
        "coachVerification.form.aboutLabel": [
            .english: "About *",
            .french: "À propos *",
            .arabic: "نبذة *"
        ],
        "coachVerification.form.locationLabel": [
            .english: "Location *",
            .french: "Localisation *",
            .arabic: "الموقع *"
        ],
        "coachVerification.form.locationPlaceholder": [
            .english: "City, State",
            .french: "Ville, Région",
            .arabic: "المدينة، الولاية"
        ],
        "coachVerification.form.websiteLabel": [
            .english: "Website / Social Media",
            .french: "Site web / Réseaux sociaux",
            .arabic: "الموقع / التواصل الاجتماعي"
        ],
        "coachVerification.form.websitePlaceholder": [
            .english: "https://...",
            .french: "https://...",
            .arabic: "https://..."
        ],
        "coachVerification.upload.title": [
            .english: "Upload Verification Documents *",
            .french: "Télécharger les documents de vérification *",
            .arabic: "رفع مستندات التحقق *"
        ],
        "coachVerification.upload.main": [
            .english: "Upload ID, Certifications, or Business License",
            .french: "Téléchargez une pièce d'identité, des certificats ou une licence",
            .arabic: "قم برفع الهوية أو الشهادات أو السجل التجاري"
        ],
        "coachVerification.upload.hint": [
            .english: "PNG, JPG, or HEIC (max 5MB each)",
            .french: "PNG, JPG ou HEIC (5 Mo max chacun)",
            .arabic: "PNG أو JPG أو HEIC (بحد أقصى 5 ميجابايت لكل ملف)"
        ],
        "coachVerification.documents.selected": [
            .english: "Selected Documents",
            .french: "Documents sélectionnés",
            .arabic: "المستندات المختارة"
        ],
        "coachVerification.button.submit": [
            .english: "Submit Application",
            .french: "Envoyer la demande",
            .arabic: "إرسال الطلب"
        ],
        "coachVerification.button.alreadyVerified": [
            .english: "Already Verified",
            .french: "Déjà vérifié",
            .arabic: "تم التحقق مسبقاً"
        ],
        "coachVerification.sheet.title": [
            .english: "Upload from",
            .french: "Télécharger depuis",
            .arabic: "التحميل من"
        ],
        "coachVerification.sheet.library": [
            .english: "Photo Library",
            .french: "Photothèque",
            .arabic: "ألبوم الصور"
        ],
        "coachVerification.sheet.files": [
            .english: "Files",
            .french: "Fichiers",
            .arabic: "الملفات"
        ],
        "coachVerification.status.confidenceScore": [
            .english: "Confidence Score",
            .french: "Score de confiance",
            .arabic: "درجة الثقة"
        ],
        "coachVerification.status.verificationReasons": [
            .english: "Verification Reasons",
            .french: "Raisons de la vérification",
            .arabic: "أسباب التحقق"
        ],
        "coachVerification.status.modifyData": [
            .english: "Modify my data",
            .french: "Modifier mes données",
            .arabic: "تعديل بياناتي"
        ],
        "coachVerification.status.reapply": [
            .english: "Reapply",
            .french: "Repostuler",
            .arabic: "إعادة التقديم"
        ],
        "coachVerification.form.nameLabel.coach": [
            .english: "Full Name *",
            .french: "Nom complet *",
            .arabic: "الاسم الكامل *"
        ],
        "coachVerification.form.nameLabel.club": [
            .english: "Club Name *",
            .french: "Nom du club *",
            .arabic: "اسم النادي *"
        ],
        "coachVerification.form.namePlaceholder.coach": [
            .english: "John Smith",
            .french: "John Smith",
            .arabic: "John Smith"
        ],
        "coachVerification.form.namePlaceholder.club": [
            .english: "SportHub LA",
            .french: "SportHub LA",
            .arabic: "SportHub LA"
        ],
        "coachVerification.form.bioPlaceholder.coach": [
            .english: "Tell us about your coaching experience and philosophy...",
            .french: "Parlez-nous de votre expérience et de votre philosophie de coaching...",
            .arabic: "حدثنا عن خبرتك في التدريب وأسلوبك..."
        ],
        "coachVerification.form.bioPlaceholder.club": [
            .english: "Describe your club, facilities, and what makes you special...",
            .french: "Décrivez votre club, vos installations et ce qui vous rend unique...",
            .arabic: "صف ناديك ومرافقك وما يميزك..."
        ],
        "coachVerification.form.specializationLabel.coach": [
            .english: "Specialization *",
            .french: "Spécialisation *",
            .arabic: "التخصص *"
        ],
        "coachVerification.form.specializationLabel.club": [
            .english: "Sport Focus *",
            .french: "Sport principal *",
            .arabic: "الرياضة الأساسية *"
        ],
        "coachVerification.form.specializationPlaceholder.coach": [
            .english: "Running, Fitness",
            .french: "Course, Fitness",
            .arabic: "الجري، اللياقة"
        ],
        "coachVerification.form.specializationPlaceholder.club": [
            .english: "Tennis, Swimming",
            .french: "Tennis, Natation",
            .arabic: "التنس، السباحة"
        ],
        "coachVerification.form.certificationsLabel": [
            .english: "Certifications / License *",
            .french: "Certifications / Licence *",
            .arabic: "الشهادات / الترخيص *"
        ],
        "coachVerification.form.certificationsPlaceholder.coach": [
            .english: "NASM CPT, ACE, etc.",
            .french: "NASM CPT, ACE, etc.",
            .arabic: "NASM CPT, ACE، إلخ"
        ],
        "coachVerification.form.certificationsPlaceholder.club": [
            .english: "Business License Number",
            .french: "Numéro de licence commerciale",
            .arabic: "رقم السجل التجاري"
        ],
        "coachVerification.form.experience.label": [
            .english: "Years of Experience *",
            .french: "Années d'expérience *",
            .arabic: "سنوات الخبرة *"
        ],
        "coachVerification.form.experience.option.select": [
            .english: "Select years",
            .french: "Sélectionnez les années",
            .arabic: "اختر عدد السنوات"
        ],
        "coachVerification.form.experience.option.1-2": [
            .english: "1-2 years",
            .french: "1-2 ans",
            .arabic: "سنة-سنتان"
        ],
        "coachVerification.form.experience.option.3-5": [
            .english: "3-5 years",
            .french: "3-5 ans",
            .arabic: "3-5 سنوات"
        ],
        "coachVerification.form.experience.option.5-10": [
            .english: "5-10 years",
            .french: "5-10 ans",
            .arabic: "5-10 سنوات"
        ],
        "coachVerification.form.experience.option.10+": [
            .english: "10+ years",
            .french: "10+ ans",
            .arabic: "أكثر من 10 سنوات"
        ],
        "coachVerification.error.nameRequired.coach": [
            .english: "Full name is required",
            .french: "Le nom complet est requis",
            .arabic: "الاسم الكامل مطلوب"
        ],
        "coachVerification.error.nameRequired.club": [
            .english: "Club name is required",
            .french: "Le nom du club est requis",
            .arabic: "اسم النادي مطلوب"
        ],
        "coachVerification.error.bioRequired": [
            .english: "About section is required",
            .french: "La section À propos est requise",
            .arabic: "قسم النبذة مطلوب"
        ],
        "coachVerification.error.bioTooShort": [
            .english: "Please provide at least 20 characters",
            .french: "Veuillez saisir au moins 20 caractères",
            .arabic: "يرجى كتابة 20 حرفاً على الأقل"
        ],
        "coachVerification.error.specializationRequired.coach": [
            .english: "Specialization is required",
            .french: "La spécialisation est requise",
            .arabic: "التخصص مطلوب"
        ],
        "coachVerification.error.specializationRequired.club": [
            .english: "Sport focus is required",
            .french: "Le sport principal est requis",
            .arabic: "الرياضة الأساسية مطلوبة"
        ],
        "coachVerification.error.experienceRequired": [
            .english: "Please select years of experience",
            .french: "Veuillez sélectionner vos années d'expérience",
            .arabic: "يرجى اختيار سنوات الخبرة"
        ],
        "coachVerification.error.certificationsRequired.coach": [
            .english: "Certifications are required",
            .french: "Les certifications sont requises",
            .arabic: "الشهادات مطلوبة"
        ],
        "coachVerification.error.certificationsRequired.club": [
            .english: "License is required",
            .french: "La licence est requise",
            .arabic: "الترخيص مطلوب"
        ],
        "coachVerification.error.locationRequired": [
            .english: "Location is required",
            .french: "La localisation est requise",
            .arabic: "الموقع مطلوب"
        ],
        "coachVerification.error.documentsRequired": [
            .english: "Please upload at least one verification document",
            .french: "Veuillez télécharger au moins un document de vérification",
            .arabic: "يرجى رفع مستند تحقق واحد على الأقل"
        ],
        "coachVerification.error.genericRequired": [
            .english: "Please fill in all required fields",
            .french: "Veuillez remplir tous les champs requis",
            .arabic: "يرجى ملء جميع الحقول المطلوبة"
        ],
        "coachVerification.error.authRequired": [
            .english: "Authentication required to submit coach verification.",
            .french: "Authentification requise pour envoyer la vérification coach.",
            .arabic: "يلزم تسجيل الدخول لإرسال طلب التحقق كمدرب."
        ],
        "coachVerification.error.couldNotVerify": [
            .english: "We could not verify your coach credentials. Please review your details and documents.",
            .french: "Nous n'avons pas pu vérifier vos informations. Veuillez vérifier vos données et documents.",
            .arabic: "تعذر التحقق من بياناتك كمدرب. يرجى مراجعة معلوماتك ومستنداتك."
        ],
        "coachVerification.status.pending.title": [
            .english: "Verification Pending",
            .french: "Vérification en attente",
            .arabic: "التحقق قيد المراجعة"
        ],
        "coachVerification.status.pending.message": [
            .english: "Your application is under review. We typically respond within 2–3 business days.",
            .french: "Votre demande est en cours d'examen. Nous répondons généralement sous 2 à 3 jours ouvrés.",
            .arabic: "طلبك قيد المراجعة. عادةً نرد خلال 2–3 أيام عمل."
        ],
        "coachVerification.status.approved.title": [
            .english: "Verified!",
            .french: "Vérifié !",
            .arabic: "تم التحقق!"
        ],
        "coachVerification.status.approved.message": [
            .english: "Congratulations! Your account has been verified. You can now create paid sessions and access coach features.",
            .french: "Félicitations ! Votre compte a été vérifié. Vous pouvez maintenant créer des sessions payantes et accéder aux fonctionnalités coach.",
            .arabic: "تهانينا! تم التحقق من حسابك. يمكنك الآن إنشاء جلسات مدفوعة والوصول إلى ميزات المدربين."
        ],
        "coachVerification.status.rejected.title": [
            .english: "Application Rejected",
            .french: "Demande refusée",
            .arabic: "تم رفض الطلب"
        ],
        "coachVerification.status.rejected.message": [
            .english: "Unfortunately, we couldn't verify your credentials. Please review your information and reapply.",
            .french: "Malheureusement, nous n'avons pas pu vérifier vos informations. Veuillez vérifier vos données et repostuler.",
            .arabic: "للأسف لم نتمكن من التحقق من بياناتك. يرجى مراجعة المعلومات وإعادة التقديم."
        ],
        "coachVerification.status.verifiedBadge.coach": [
            .english: "Verified Coach",
            .french: "Coach vérifié",
            .arabic: "مدرب موثّق"
        ],
        "coachVerification.status.verifiedBadge.club": [
            .english: "Verified Club",
            .french: "Club vérifié",
            .arabic: "نادي موثّق"
        ],
        
        // Edit Profile
        "profile.edit.header.title": [
            .english: "Edit Profile",
            .french: "Modifier le profil",
            .arabic: "تعديل الملف الشخصي"
        ],
        "profile.edit.loading.saving": [
            .english: "Saving profile...",
            .french: "Enregistrement du profil...",
            .arabic: "جارٍ حفظ الملف الشخصي..."
        ],
        "profile.edit.photo.change": [
            .english: "Tap to change photo",
            .french: "Touchez pour changer la photo",
            .arabic: "اضغط لتغيير الصورة"
        ],
        "profile.edit.section.basicInfo": [
            .english: "Basic Information",
            .french: "Informations de base",
            .arabic: "معلومات أساسية"
        ],
        "profile.edit.section.aboutMe": [
            .english: "About Me",
            .french: "À propos de moi",
            .arabic: "نبذة عني"
        ],
        "profile.edit.section.sportsInterests": [
            .english: "Sports Interests",
            .french: "Sports favoris",
            .arabic: "الاهتمامات الرياضية"
        ],
        "profile.edit.sports.description": [
            .english: "Select the sports you're interested in",
            .french: "Sélectionnez les sports qui vous intéressent",
            .arabic: "اختر الرياضات التي تهتم بها"
        ],
        "profile.edit.sports.selectedSuffix": [
            .english: "selected",
            .french: "sélectionnés",
            .arabic: "مختارة"
        ],
        "profile.edit.section.emailVerification": [
            .english: "Email Verification",
            .french: "Vérification de l'e-mail",
            .arabic: "التحقق من البريد الإلكتروني"
        ],
        "profile.edit.email.verified": [
            .english: "Verified",
            .french: "Vérifié",
            .arabic: "مُتحقق منه"
        ],
        "profile.edit.email.sendVerification": [
            .english: "Send Verification Email",
            .french: "Envoyer l'e-mail de vérification",
            .arabic: "إرسال بريد التحقق"
        ],
        
        // Change Password
        "password.header.title": [
            .english: "Change Password",
            .french: "Changer le mot de passe",
            .arabic: "تغيير كلمة المرور"
        ],
        "password.loading.changing": [
            .english: "Changing password...",
            .french: "Changement du mot de passe...",
            .arabic: "جارٍ تغيير كلمة المرور..."
        ],
        "password.section.info": [
            .english: "Password Information",
            .french: "Informations sur le mot de passe",
            .arabic: "معلومات كلمة المرور"
        ],
        "password.section.requirementsTitle": [
            .english: "Password Requirements:",
            .french: "Exigences du mot de passe :",
            .arabic: "متطلبات كلمة المرور:"
        ],
        "password.strength.title": [
            .english: "Password Strength:",
            .french: "Niveau de sécurité :",
            .arabic: "قوة كلمة المرور:"
        ],
        "password.field.current": [
            .english: "Current Password",
            .french: "Mot de passe actuel",
            .arabic: "كلمة المرور الحالية"
        ],
        "password.field.new": [
            .english: "New Password",
            .french: "Nouveau mot de passe",
            .arabic: "كلمة المرور الجديدة"
        ],
        "password.field.confirm": [
            .english: "Confirm New Password",
            .french: "Confirmer le nouveau mot de passe",
            .arabic: "تأكيد كلمة المرور الجديدة"
        ],
        "password.security.tipTitle": [
            .english: "Security Tip",
            .french: "Conseil de sécurité",
            .arabic: "نصيحة أمان"
        ],
        "password.security.tipMessage": [
            .english: "Use a strong password with at least 8 characters, including letters, numbers, and symbols.",
            .french: "Utilisez un mot de passe fort d'au moins 8 caractères, incluant des lettres, des chiffres et des symboles.",
            .arabic: "استخدم كلمة مرور قوية لا تقل عن 8 أحرف، تحتوي على حروف وأرقام ورموز."
        ],
        "password.requirements.length": [
            .english: "At least 8 characters long",
            .french: "Au moins 8 caractères",
            .arabic: "لا تقل عن 8 أحرف"
        ],
        "password.requirements.letters": [
            .english: "Include uppercase and lowercase letters",
            .french: "Inclure des lettres majuscules et minuscules",
            .arabic: "تتضمن حروفاً كبيرة وصغيرة"
        ],
        "password.requirements.number": [
            .english: "Include at least one number",
            .french: "Inclure au moins un chiffre",
            .arabic: "تتضمن رقمًا واحدًا على الأقل"
        ],
        "password.requirements.special": [
            .english: "Include at least one special character",
            .french: "Inclure au moins un caractère spécial",
            .arabic: "تتضمن رمزاً خاصاً واحداً على الأقل"
        ],
        "password.strength.weak": [
            .english: "Weak",
            .french: "Faible",
            .arabic: "ضعيفة"
        ],
        "password.strength.fair": [
            .english: "Fair",
            .french: "Moyenne",
            .arabic: "متوسطة"
        ],
        "password.strength.good": [
            .english: "Good",
            .french: "Bonne",
            .arabic: "جيدة"
        ],
        "password.strength.strong": [
            .english: "Strong",
            .french: "Très bonne",
            .arabic: "قوية"
        ],
        "password.error.currentRequired": [
            .english: "Current password is required",
            .french: "Le mot de passe actuel est requis",
            .arabic: "كلمة المرور الحالية مطلوبة"
        ],
        "password.error.newRequired": [
            .english: "New password is required",
            .french: "Le nouveau mot de passe est requis",
            .arabic: "كلمة المرور الجديدة مطلوبة"
        ],
        "password.error.minLength": [
            .english: "Password must be at least 8 characters",
            .french: "Le mot de passe doit contenir au moins 8 caractères",
            .arabic: "يجب أن لا تقل كلمة المرور عن 8 أحرف"
        ],
        "password.error.notStrongEnough": [
            .english: "Password does not meet requirements",
            .french: "Le mot de passe ne respecte pas les exigences",
            .arabic: "كلمة المرور لا تلبي المتطلبات"
        ],
        "password.error.sameAsCurrent": [
            .english: "New password must be different from current password",
            .french: "Le nouveau mot de passe doit être différent de l'actuel",
            .arabic: "يجب أن تكون كلمة المرور الجديدة مختلفة عن الحالية"
        ],
        "password.error.confirmRequired": [
            .english: "Please confirm your password",
            .french: "Veuillez confirmer votre mot de passe",
            .arabic: "يرجى تأكيد كلمة المرور"
        ],
        "password.error.mismatch": [
            .english: "Passwords do not match",
            .french: "Les mots de passe ne correspondent pas",
            .arabic: "كلمتا المرور غير متطابقتين"
        ],
        "password.error.notAuthenticated": [
            .english: "Not authenticated. Please log in again.",
            .french: "Non authentifié. Veuillez vous reconnecter.",
            .arabic: "غير مصدّق. يرجى تسجيل الدخول مرة أخرى."
        ],
        
        // Activity Room - General & Alerts
        "activityRoom.nav.title.format": [
            .english: "%@ Session",
            .french: "Session %@",
            .arabic: "جلسة %@"
        ],
        "activityRoom.nav.subtitle.format": [
            .english: "Hosted by %@",
            .french: "Animé par %@",
            .arabic: "ينظمها %@"
        ],
        "activityRoom.info.getDirections": [
            .english: "Get Directions",
            .french: "Obtenir l'itinéraire",
            .arabic: "الحصول على الاتجاهات"
        ],
        "activityRoom.info.startsInPlaceholder": [
            .english: "Starts in 2 hours",
            .french: "Commence dans 2 heures",
            .arabic: "تبدأ بعد ساعتين"
        ],
        "activityRoom.info.spotsLeftSuffix": [
            .english: "spots left",
            .french: "places restantes",
            .arabic: "أماكن متبقية"
        ],
        "activityRoom.alert.leave.title": [
            .english: "Leave Activity",
            .french: "Quitter l'activité",
            .arabic: "مغادرة النشاط"
        ],
        "activityRoom.alert.leave.message": [
            .english: "Are you sure you want to leave this activity?",
            .french: "Êtes-vous sûr de vouloir quitter cette activité ?",
            .arabic: "هل أنت متأكد أنك تريد مغادرة هذا النشاط؟"
        ],
        "activityRoom.alert.complete.title": [
            .english: "Complete Activity",
            .french: "Terminer l'activité",
            .arabic: "إنهاء النشاط"
        ],
        "activityRoom.alert.complete.message": [
            .english: "Mark this activity as complete?",
            .french: "Marquer cette activité comme terminée ?",
            .arabic: "وضع علامة أن هذا النشاط مكتمل؟"
        ],
        "activityRoom.tab.chat": [
            .english: "Chat",
            .french: "Chat",
            .arabic: "الدردشة"
        ],
        "activityRoom.tab.participants": [
            .english: "People",
            .french: "Participants",
            .arabic: "الأشخاص"
        ],
        "activityRoom.tab.ai": [
            .english: "AI Tips",
            .french: "Conseils IA",
            .arabic: "نصائح الذكاء الاصطناعي"
        ],
        "activityRoom.tab.info": [
            .english: "Info",
            .french: "Infos",
            .arabic: "معلومات"
        ],
        "activityRoom.alert.maps.title": [
            .english: "Choose Maps App",
            .french: "Choisir l'application de cartes",
            .arabic: "اختر تطبيق الخرائط"
        ],
        "activityRoom.alert.maps.message": [
            .english: "Choose which maps app to use for directions to %@",
            .french: "Choisissez l'application de cartes à utiliser pour aller à %@",
            .arabic: "اختر تطبيق الخرائط لاستخدامه في التوجيه إلى %@"
        ],
        "activityRoom.button.leave": [
            .english: "Leave",
            .french: "Quitter",
            .arabic: "مغادرة"
        ],
        "activityRoom.button.complete": [
            .english: "Complete",
            .french: "Terminer",
            .arabic: "إكمال"
        ],
        "activityRoom.maps.apple": [
            .english: "Apple Maps",
            .french: "Apple Maps",
            .arabic: "خرائط آبل"
        ],
        "activityRoom.maps.google": [
            .english: "Google Maps",
            .french: "Google Maps",
            .arabic: "خرائط جوجل"
        ],
        "activityRoom.participant.genericName": [
            .english: "Participant",
            .french: "Participant",
            .arabic: "مشارك"
        ],
        "activityRoom.participants.status.host": [
            .english: "Host",
            .french: "Hôte",
            .arabic: "المضيف"
        ],
        "activityRoom.participants.status.joined": [
            .english: "Joined",
            .french: "Inscrit",
            .arabic: "منضم"
        ],
        
        // Activity Room - AI Tips & Info Tab
        "activity.info.aboutTitle": [
            .english: "About",
            .french: "À propos",
            .arabic: "حول"
        ],
        "activity.info.detailsTitle": [
            .english: "Details",
            .french: "Détails",
            .arabic: "تفاصيل"
        ],
        "activity.info.dateTime": [
            .english: "Date & Time",
            .french: "Date et heure",
            .arabic: "التاريخ والوقت"
        ],
        "activity.info.location": [
            .english: "Location",
            .french: "Lieu",
            .arabic: "الموقع"
        ],
        "activity.info.participants": [
            .english: "Participants",
            .french: "Participants",
            .arabic: "المشاركون"
        ],
        "activity.info.skillLevel": [
            .english: "Skill Level",
            .french: "Niveau de compétence",
            .arabic: "مستوى المهارة"
        ],
        "activityRoom.ai.motivation.title": [
            .english: "\"Progress starts with small steps\"",
            .french: "\"Le progrès commence par de petits pas\"",
            .arabic: "\"التقدّم يبدأ بخطوات صغيرة\""
        ],
        "activityRoom.ai.motivation.description": [
            .english: "Stay consistent and you'll reach your goals! 💪",
            .french: "Restez constant et vous atteindrez vos objectifs ! 💪",
            .arabic: "حافظ على الاستمرارية وستصل إلى أهدافك! 💪"
        ],
        "activityRoom.ai.weather.title": [
            .english: "Perfect weather conditions",
            .french: "Conditions météo idéales",
            .arabic: "أجواء مثالية"
        ],
        "activityRoom.ai.weather.description": [
            .english: "72°F, sunny — ideal for outdoor activity",
            .french: "72°F, ensoleillé — idéal pour une activité en plein air",
            .arabic: "°72 فهرنهايت، مشمس — مثالي لنشاط خارجي"
        ],
        "activityRoom.ai.weather.extra": [
            .english: "💡 Great conditions for %@. Remember to bring sunscreen!",
            .french: "💡 Excellentes conditions pour %@. N'oubliez pas la crème solaire !",
            .arabic: "💡 ظروف رائعة لـ %@. لا تنس إحضار واقي الشمس!"
        ],
        "activityRoom.ai.group.title": [
            .english: "Optimal group size",
            .french: "Taille de groupe optimale",
            .arabic: "حجم مجموعة مثالي"
        ],
        "activityRoom.ai.group.descriptionSuffix": [
            .english: "participants — perfect for engagement",
            .french: "participants — parfait pour l'engagement",
            .arabic: "مشاركين — مثالي للتفاعل"
        ],
        "activityRoom.ai.group.extra": [
            .english: "✓ Not too crowded — you'll get personalized attention",
            .french: "✓ Pas trop de monde — vous aurez une attention personnalisée",
            .arabic: "✓ غير مزدحم — ستحصل على اهتمام شخصي"
        ],
        "activityRoom.ai.timing.title": [
            .english: "Timing suggestion",
            .french: "Suggestion de timing",
            .arabic: "اقتراح توقيت"
        ],
        "activityRoom.ai.timing.description": [
            .english: "Arrive 10 minutes early for warm-up",
            .french: "Arrivez 10 minutes en avance pour vous échauffer",
            .arabic: "احضر قبل 10 دقائق للإحماء"
        ],
        "activityRoom.ai.safety.title": [
            .english: "Safety reminders",
            .french: "Rappels de sécurité",
            .arabic: "تذكيرات للسلامة"
        ],
        "activityRoom.ai.safety.bullet1": [
            .english: "Stay hydrated throughout the session",
            .french: "Restez hydraté pendant toute la séance",
            .arabic: "حافظ على ترطيب جسمك طوال الجلسة"
        ],
        "activityRoom.ai.safety.bullet2": [
            .english: "Listen to your body and take breaks when needed",
            .french: "Écoutez votre corps et faites des pauses si nécessaire",
            .arabic: "استمع إلى جسدك وخذ فترات راحة عند الحاجة"
        ],
        "activityRoom.ai.safety.bullet3": [
            .english: "Inform the host of any health concerns",
            .french: "Informez l'hôte de tout problème de santé",
            .arabic: "أبلغ المضيف بأي مشكلات صحية"
        ],
        "activityRoom.ai.match.title": [
            .english: "AI says this is a great match!",
            .french: "L'IA indique que c'est un excellent choix !",
            .arabic: "الذكاء الاصطناعي يقول إن هذا اختيار رائع!"
        ],
        "activityRoom.ai.match.description": [
            .english: "Based on your profile, this activity matches your skill level and interests. Enjoy!",
            .french: "D'après votre profil, cette activité correspond à votre niveau et à vos centres d'intérêt. Profitez-en !",
            .arabic: "استنادًا إلى ملفك الشخصي، هذا النشاط يناسب مستواك واهتماماتك. استمتع!"
        ],
        
        // Chat (Activity Room, etc.)
        "chat.input.placeholder": [
            .english: "Type a message...",
            .french: "Écrire un message...",
            .arabic: "اكتب رسالة..."
        ],
        "chat.sender.you": [
            .english: "You",
            .french: "Vous",
            .arabic: "أنت"
        ],
        "chat.sender.system": [
            .english: "System",
            .french: "Système",
            .arabic: "النظام"
        ],
        "chat.system.refreshMessage": [
            .english: "Messages refreshed at %@",
            .french: "Messages actualisés à %@",
            .arabic: "تم تحديث الرسائل في %@"
        ],
        "chat.list.header.title": [
            .english: "Messages",
            .french: "Messages",
            .arabic: "الرسائل"
        ],
        "chat.list.search.placeholder": [
            .english: "Search people or conversations...",
            .french: "Rechercher des personnes ou des conversations...",
            .arabic: "ابحث عن أشخاص أو محادثات..."
        ],
        "chat.list.search.searchingUsers": [
            .english: "Searching people…",
            .french: "Recherche de personnes…",
            .arabic: "جارٍ البحث عن الأشخاص..."
        ],
        "chat.list.section.people": [
            .english: "People",
            .french: "Personnes",
            .arabic: "الأشخاص"
        ],
        "chat.list.section.conversations": [
            .english: "Conversations",
            .french: "Conversations",
            .arabic: "المحادثات"
        ],
        "chat.list.loading": [
            .english: "Loading conversations...",
            .french: "Chargement des conversations...",
            .arabic: "جارٍ تحميل المحادثات..."
        ],
        "chat.list.empty.title": [
            .english: "No results",
            .french: "Aucun résultat",
            .arabic: "لا توجد نتائج"
        ],
        "chat.list.empty.subtitle": [
            .english: "Try a different name or keyword",
            .french: "Essayez un autre nom ou mot-clé",
            .arabic: "جرّب اسمًا أو كلمة مفتاحية مختلفة"
        ],
        "chat.list.empty.clearButton": [
            .english: "Clear Search",
            .french: "Effacer la recherche",
            .arabic: "مسح البحث"
        ],
        "chat.row.groupBadge": [
            .english: "Group",
            .french: "Groupe",
            .arabic: "مجموعة"
        ],
        "chat.searchRow.tapToChat": [
            .english: "Tap to chat",
            .french: "Touchez pour discuter",
            .arabic: "اضغط لبدء الدردشة"
        ],
        "chat.group.leave.title": [
            .english: "Leave Group",
            .french: "Quitter le groupe",
            .arabic: "مغادرة المجموعة"
        ],
        "chat.group.leave.message": [
            .english: "Are you sure you want to leave this group chat? You will no longer receive messages from this group.",
            .french: "Voulez-vous vraiment quitter cette discussion de groupe ? Vous ne recevrez plus de messages de ce groupe.",
            .arabic: "هل أنت متأكد أنك تريد مغادرة محادثة المجموعة هذه؟ لن تتلقى رسائل من هذه المجموعة بعد الآن."
        ],
        "chat.group.menu.viewParticipants": [
            .english: "View participants",
            .french: "Voir les participants",
            .arabic: "عرض المشاركين"
        ],
        "chat.group.menu.viewCreatorProfile": [
            .english: "View creator profile",
            .french: "Voir le profil du créateur",
            .arabic: "عرض ملف المنشئ"
        ],
        "chat.group.menu.leaveGroup": [
            .english: "Leave Group",
            .french: "Quitter le groupe",
            .arabic: "مغادرة المجموعة"
        ],
        "chat.direct.menu.showProfile": [
            .english: "Show profile",
            .french: "Afficher le profil",
            .arabic: "عرض الملف الشخصي"
        ],
        "chat.header.group.titleFallback": [
            .english: "Group chat",
            .french: "Discussion de groupe",
            .arabic: "دردشة جماعية"
        ],
        "chat.header.group.participantsFormat": [
            .english: "%d participants",
            .french: "%d participants",
            .arabic: "%d مشاركين"
        ],
        "chat.participantsPopup.title": [
            .english: "Participants",
            .french: "Participants",
            .arabic: "المشاركون"
        ],
        "chat.participantsPopup.closeButton": [
            .english: "Close",
            .french: "Fermer",
            .arabic: "إغلاق"
        ],
        "chat.profile.about.title": [
            .english: "About",
            .french: "À propos",
            .arabic: "نبذة"
        ],
        "chat.profile.about.empty": [
            .english: "No public description available yet.",
            .french: "Aucune description publique pour le moment.",
            .arabic: "لا توجد نبذة عامة متاحة بعد."
        ],
        "chat.profile.favoriteSports.title": [
            .english: "Favorite Sports",
            .french: "Sports favoris",
            .arabic: "الرياضات المفضلة"
        ],
        "chat.profile.favoriteSports.empty": [
            .english: "No favorite sports added yet.",
            .french: "Aucun sport favori ajouté pour le moment.",
            .arabic: "لم تتم إضافة رياضات مفضلة بعد."
        ],
        "chat.profile.closeButton": [
            .english: "Close",
            .french: "Fermer",
            .arabic: "إغلاق"
        ],
        "chat.input.sendButton": [
            .english: "Send",
            .french: "Envoyer",
            .arabic: "إرسال"
        ],
        "chat.header.direct.fallbackTitle": [
            .english: "Conversation",
            .french: "Conversation",
            .arabic: "محادثة"
        ],
        
        // Enhanced Event Details
        "eventDetails.nav.title": [
            .english: "Event Details",
            .french: "Détails de l'événement",
            .arabic: "تفاصيل الحدث"
        ],
        "eventDetails.tab.details": [
            .english: "Details",
            .french: "Détails",
            .arabic: "التفاصيل"
        ],
        "eventDetails.tab.participants": [
            .english: "Participants",
            .french: "Participants",
            .arabic: "المشاركون"
        ],
        "eventDetails.verifiedCoachBadge": [
            .english: "✓ Hosted by Verified Coach",
            .french: "✓ Animé par un coach vérifié",
            .arabic: "✓ من تنظيم مدرب موثّق"
        ],
        "eventDetails.info.date": [
            .english: "Date",
            .french: "Date",
            .arabic: "التاريخ"
        ],
        "eventDetails.info.level": [
            .english: "Level",
            .french: "Niveau",
            .arabic: "المستوى"
        ],
        "eventDetails.info.startTime": [
            .english: "Start Time",
            .french: "Heure de début",
            .arabic: "وقت البدء"
        ],
        "eventDetails.info.endTime": [
            .english: "End Time",
            .french: "Heure de fin",
            .arabic: "وقت الانتهاء"
        ],
        "eventDetails.about.title": [
            .english: "About this session",
            .french: "À propos de cette session",
            .arabic: "حول هذه الجلسة"
        ],
        "eventDetails.participants.joinedLabel": [
            .english: "Joined this event",
            .french: "A rejoint cet événement",
            .arabic: "انضم إلى هذا الحدث"
        ],
        "eventDetails.participants.viewButton": [
            .english: "View",
            .french: "Voir",
            .arabic: "عرض"
        ],
        "eventDetails.participants.countSuffix": [
            .english: "people are joining this session",
            .french: "personnes participent à cette session",
            .arabic: "أشخاص سينضمون إلى هذه الجلسة"
        ],
        "eventDetails.price.free": [
            .english: "Free",
            .french: "Gratuit",
            .arabic: "مجاني"
        ],
        "eventDetails.availability.title": [
            .english: "Availability",
            .french: "Disponibilité",
            .arabic: "التوفر"
        ],
        "eventDetails.availability.joinedSuffix": [
            .english: "joined",
            .french: "inscrits",
            .arabic: "منضمين"
        ],
        "eventDetails.availability.spotsLeftSuffix": [
            .english: "spots left",
            .french: "places restantes",
            .arabic: "أماكن متبقية"
        ],
        "eventDetails.availability.warningAlmostFull": [
            .english: "⚠️ Almost full - book now!",
            .french: "⚠️ Presque complet - réservez maintenant !",
            .arabic: "⚠️ الأماكن تكاد تنفد - سارع بالحجز!"
        ],
        "eventDetails.coach.reviewsSuffix": [
            .english: "reviews",
            .french: "avis",
            .arabic: "تقييمات"
        ],
        "eventDetails.coach.viewProfile": [
            .english: "View Profile",
            .french: "Voir le profil",
            .arabic: "عرض الملف الشخصي"
        ],
        "eventDetails.bottom.totalLabel": [
            .english: "Total",
            .french: "Total",
            .arabic: "المجموع"
        ],
        "eventDetails.bottom.checkSession": [
            .english: "Check session",
            .french: "Voir la session",
            .arabic: "عرض الجلسة"
        ],
        "eventDetails.bottom.bookNow": [
            .english: "Book Now",
            .french: "Réserver maintenant",
            .arabic: "احجز الآن"
        ],
        "eventDetails.bottom.editEvent": [
            .english: "Edit Event",
            .french: "Modifier l'événement",
            .arabic: "تعديل الحدث"
        ],
        "eventDetails.bottom.manageParticipants": [
            .english: "Manage Participants",
            .french: "Gérer les participants",
            .arabic: "إدارة المشاركين"
        ],
        "eventDetails.payment.success.title": [
            .english: "Payment successful",
            .french: "Paiement réussi",
            .arabic: "اكتملت عملية الدفع بنجاح"
        ],
        "eventDetails.payment.success.message": [
            .english: "You're all set for this session.",
            .french: "Tout est prêt pour votre session.",
            .arabic: "أصبحت جاهزًا لهذه الجلسة."
        ],
        "eventDetails.payment.success.proceedButton": [
            .english: "Proceed to session",
            .french: "Accéder à la session",
            .arabic: "الانتقال إلى الجلسة"
        ],
        "eventDetails.payment.success.backHomeButton": [
            .english: "Back home",
            .french: "Retour à l'accueil",
            .arabic: "العودة إلى الصفحة الرئيسية"
        ],
        "eventDetails.payment.error.failed": [
            .english: "Payment failed. Please try again.",
            .french: "Le paiement a échoué. Veuillez réessayer.",
            .arabic: "فشلت عملية الدفع. يرجى المحاولة مرة أخرى."
        ],
        
        // Share / Invite
        "share.activity.inviteTitle": [
            .english: "Join me for this sports activity!",
            .french: "Rejoignez-moi pour cette activité sportive !",
            .arabic: "انضم إليّ في هذا النشاط الرياضي!"
        ],
        "share.activity.sportLabel": [
            .english: "Sport:",
            .french: "Sport :",
            .arabic: "الرياضة:"
        ],
        "share.activity.locationLabel": [
            .english: "Location:",
            .french: "Lieu :",
            .arabic: "الموقع:"
        ],
        "share.activity.dateLabel": [
            .english: "Date:",
            .french: "Date :",
            .arabic: "التاريخ:"
        ],
        "share.activity.timeLabel": [
            .english: "Time:",
            .french: "Heure :",
            .arabic: "الوقت:"
        ],
        "share.activity.priceLabel": [
            .english: "Price:",
            .french: "Prix :",
            .arabic: "السعر:"
        ],
        "share.session.inviteTitle": [
            .english: "My coaching session is live – join me!",
            .french: "Ma séance de coaching est en ligne – rejoignez-moi !",
            .arabic: "جلسة التدريب الخاصة بي بدأت – انضم إليّ!"
        ],
        "share.coach.inviteTitle": [
            .english: "Check out this coach on NEXO!",
            .french: "Découvrez ce coach sur NEXO !",
            .arabic: "اطّلع على هذا المدرّب على NEXO!"
        ],
        "share.coach.locationLabel": [
            .english: "Location:",
            .french: "Lieu :",
            .arabic: "الموقع:"
        ],
        "share.coach.ratingLabel": [
            .english: "Rating:",
            .french: "Note :",
            .arabic: "التقييم:"
        ],
        "share.coach.fallback": [
            .english: "Check out this coach on NEXO!",
            .french: "Découvrez ce coach sur NEXO !",
            .arabic: "اطّلع على هذا المدرّب على NEXO!"
        ],
        "share.common.appSuffix": [
            .english: "Shared from NEXO",
            .french: "Partagé depuis NEXO",
            .arabic: "تمت المشاركة من NEXO"
        ],
        
        // QuickMatch & AI Matchmaker
        "quickMatch.nav.title": [
            .english: "Quick Match",
            .french: "Match rapide",
            .arabic: "مطابقة سريعة"
        ],
        "quickMatch.stats.rating": [
            .english: "Rating",
            .french: "Note",
            .arabic: "التقييم"
        ],
        "quickMatch.stats.activities": [
            .english: "Activities",
            .french: "Activités",
            .arabic: "الأنشطة"
        ],
        "quickMatch.section.favoriteSports": [
            .english: "Favorite Sports",
            .french: "Sports favoris",
            .arabic: "الرياضات المفضلة"
        ],
        "quickMatch.section.interests": [
            .english: "Interests",
            .french: "Centres d'intérêt",
            .arabic: "الاهتمامات"
        ],
        "quickMatch.empty.title": [
            .english: "All caught up!",
            .french: "Vous êtes à jour !",
            .arabic: "لقد شاهدت كل شيء!"
        ],
        "quickMatch.empty.message": [
            .english: "You've seen all available profiles. Check back later for more sport buddies!",
            .french: "Vous avez vu tous les profils disponibles. Revenez plus tard pour trouver de nouveaux partenaires de sport !",
            .arabic: "لقد شاهدت جميع الملفات المتاحة. عد لاحقًا للعثور على شركاء رياضة جدد!"
        ],
        "quickMatch.empty.backButton": [
            .english: "Back to Home",
            .french: "Retour à l'accueil",
            .arabic: "العودة إلى الرئيسية"
        ],
        "quickMatch.indicator.like": [
            .english: "LIKE",
            .french: "LIKE",
            .arabic: "إعجاب"
        ],
        "quickMatch.indicator.nope": [
            .english: "NOPE",
            .french: "NOPE",
            .arabic: "تخطي"
        ],
        "quickMatch.matchModal.title": [
            .english: "It's a Match!",
            .french: "C'est un match !",
            .arabic: "إنها مطابقة!"
        ],
        "quickMatch.matchModal.subtitle": [
            .english: "You and %@ both like each other",
            .french: "Vous et %@ vous appréciez mutuellement",
            .arabic: "أنت و %@ أعجبتم ببعضكما البعض"
        ],
        "quickMatch.matchModal.status": [
            .english: "Starting a conversation...",
            .french: "Démarrage de la conversation...",
            .arabic: "بدء المحادثة..."
        ],
        "quickMatch.likesBadge.accessibility": [
            .english: "Likes %d",
            .french: "%d mentions J’aime",
            .arabic: "%d إعجابات"
        ],
        "quickMatch.profile.name.unknown": [
            .english: "Unknown",
            .french: "Inconnu",
            .arabic: "غير معروف"
        ],
        "quickMatch.profile.location.unknown": [
            .english: "Unknown",
            .french: "Inconnu",
            .arabic: "غير معروف"
        ],
        "quickMatch.profile.sport.defaultName": [
            .english: "Sport",
            .french: "Sport",
            .arabic: "رياضة"
        ],
        "quickMatch.profile.sport.defaultLevel": [
            .english: "Intermediate",
            .french: "Intermédiaire",
            .arabic: "متوسط"
        ],
        "explore.nav.title": [
            .english: "Explore More",
            .french: "Explorer plus",
            .arabic: "استكشف المزيد"
        ],
        "explore.search.placeholder": [
            .english: "Search sports, people, or places...",
            .french: "Rechercher des sports, des personnes ou des lieux...",
            .arabic: "ابحث عن رياضات أو أشخاص أو أماكن..."
        ],
        "explore.loading": [
            .english: "Loading...",
            .french: "Chargement...",
            .arabic: "جارٍ التحميل..."
        ],
        "explore.featuredCoach.title": [
            .english: "Featured Coach",
            .french: "Coach à la une",
            .arabic: "مدرّب مميز"
        ],
        "explore.featuredCoach.seeAll": [
            .english: "See All",
            .french: "Tout voir",
            .arabic: "عرض الكل"
        ],
        "explore.featuredCoach.reviewsLabel": [
            .english: "reviews",
            .french: "avis",
            .arabic: "تقييمات"
        ],
        "explore.featuredCoach.sessionsLabel": [
            .english: "sessions",
            .french: "séances",
            .arabic: "جلسات"
        ],
        "explore.categories.title": [
            .english: "Browse by Sport",
            .french: "Parcourir par sport",
            .arabic: "تصفّح حسب الرياضة"
        ],
        "explore.trending.title.searchResults": [
            .english: "Search Results",
            .french: "Résultats de recherche",
            .arabic: "نتائج البحث"
        ],
        "explore.trending.title.nearYou": [
            .english: "Trending Near You",
            .french: "Tendance près de chez vous",
            .arabic: "الأكثر رواجًا بالقرب منك"
        ],
        "explore.trending.noResultsFormat": [
            .english: "No activities found for '%@'",
            .french: "Aucune activité trouvée pour '%@'",
            .arabic: "لم يتم العثور على أنشطة لـ '%@'"
        ],
        "explore.trending.error": [
            .english: "Error loading activities",
            .french: "Erreur lors du chargement des activités",
            .arabic: "حدث خطأ أثناء تحميل الأنشطة"
        ],
        "explore.trending.empty": [
            .english: "No activities available",
            .french: "Aucune activité disponible",
            .arabic: "لا توجد أنشطة متاحة"
        ],
        
        // Map Screen
        "map.alert.chooseApp.messageFormat": [
            .english: "Choose which maps app to use for directions to %@",
            .french: "Choisissez l'application de cartes pour obtenir l'itinéraire vers %@",
            .arabic: "اختر تطبيق الخرائط لاستخدامه في التوجيه إلى %@"
        ],
        "map.alert.appleMaps": [
            .english: "Apple Maps",
            .french: "Plans (Apple Maps)",
            .arabic: "خرائط آبل"
        ],
        "map.alert.googleMaps": [
            .english: "Google Maps",
            .french: "Google Maps",
            .arabic: "خرائط جوجل"
        ],
        "map.selected.hostType.coach": [
            .english: "Coach",
            .french: "Coach",
            .arabic: "مدرب"
        ],
        "map.selected.hostType.individual": [
            .english: "Individual",
            .french: "Individuel",
            .arabic: "فردي"
        ],
        "map.selected.spotsLeftFormat": [
            .english: "%d spots left",
            .french: "%d places restantes",
            .arabic: "%d أماكن متبقية"
        ],
        "map.selected.directionsButton": [
            .english: "Directions",
            .french: "Itinéraire",
            .arabic: "الاتجاهات"
        ],
        "map.selected.joinButton": [
            .english: "Join",
            .french: "Rejoindre",
            .arabic: "انضمام"
        ],
        "map.selected.chatNowButton": [
            .english: "Chat Now",
            .french: "Discuter",
            .arabic: "ابدأ الدردشة"
        ],
        "map.aiCard.spotsRemainingFormat": [
            .english: "%d of %d spots remaining",
            .french: "%d sur %d places restantes",
            .arabic: "%d من %d أماكن متبقية"
        ],
        "map.aiCard.joinButton": [
            .english: "Join",
            .french: "Rejoindre",
            .arabic: "انضمام"
        ],
        "map.aiCard.badge.aiPick": [
            .english: "AI Pick",
            .french: "Choix de l'IA",
            .arabic: "اختيار الذكاء الاصطناعي"
        ],
        "map.banner.personalizedTitle": [
            .english: "Personalized For You",
            .french: "Personnalisé pour vous",
            .arabic: "مقترحة خصيصًا لك"
        ],
        "map.banner.personalizedDescription": [
            .english: "Based on your activity & preferences",
            .french: "Basé sur votre activité et vos préférences",
            .arabic: "استنادًا إلى نشاطك وتفضيلاتك"
        ],
        "map.whyThese.title": [
            .english: "Why these activities?",
            .french: "Pourquoi ces activités ?",
            .arabic: "لماذا هذه الأنشطة؟"
        ],
        "map.whyThese.description": [
            .english: "We've selected activities matching your skill level, preferred sports, and typical schedule. These are nearby and have availability.",
            .french: "Nous avons sélectionné des activités correspondant à votre niveau, vos sports préférés et vos horaires habituels. Elles sont proches et ont des places disponibles.",
            .arabic: "اخترنا أنشطة تناسب مستواك ورياضاتك المفضّلة وجدولك المعتاد. وهي قريبة منك وتتوفر فيها أماكن."
        ],
        
        // Create Activity
        "createActivity.nav.title": [
            .english: "Create Activity",
            .french: "Créer une activité",
            .arabic: "إنشاء نشاط"
        ],
        "createActivity.field.sportType": [
            .english: "Sport Type *",
            .french: "Type de sport *",
            .arabic: "نوع الرياضة *"
        ],
        "createActivity.field.sportType.placeholder": [
            .english: "Select a sport",
            .french: "Sélectionner un sport",
            .arabic: "اختر رياضة"
        ],
        "createActivity.field.title": [
            .english: "Activity Title *",
            .french: "Titre de l'activité *",
            .arabic: "عنوان النشاط *"
        ],
        "createActivity.field.title.placeholder": [
            .english: "e.g., Morning run at the park",
            .french: "ex. : Course matinale au parc",
            .arabic: "مثال: جري صباحي في الحديقة"
        ],
        "createActivity.field.description": [
            .english: "Description",
            .french: "Description",
            .arabic: "الوصف"
        ],
        "createActivity.field.description.placeholder": [
            .english: "Tell participants what to expect...",
            .french: "Expliquez aux participants à quoi s'attendre...",
            .arabic: "اشرح للمشاركين ما يمكنهم توقعه..."
        ],
        "createActivity.field.location": [
            .english: "Location *",
            .french: "Lieu *",
            .arabic: "الموقع *"
        ],
        "createActivity.field.location.placeholder": [
            .english: "Enter address or venue name",
            .french: "Saisir l'adresse ou le nom du lieu",
            .arabic: "أدخل العنوان أو اسم المكان"
        ],
        "createActivity.field.location.mapButton": [
            .english: "Pick from Map",
            .french: "Choisir sur la carte",
            .arabic: "الاختيار من الخريطة"
        ],
        "createActivity.field.date": [
            .english: "Date *",
            .french: "Date *",
            .arabic: "التاريخ *"
        ],
        "createActivity.field.time": [
            .english: "Time *",
            .french: "Heure *",
            .arabic: "الوقت *"
        ],
        "createActivity.field.participants.label": [
            .english: "Number of Participants: %d",
            .french: "Nombre de participants : %d",
            .arabic: "عدد المشاركين: %d"
        ],
        "createActivity.field.level": [
            .english: "Skill Level *",
            .french: "Niveau de compétence *",
            .arabic: "مستوى المهارة *"
        ],
        "createActivity.field.level.placeholder": [
            .english: "Select skill level",
            .french: "Sélectionner un niveau",
            .arabic: "اختر مستوى المهارة"
        ],
        "createActivity.field.visibility": [
            .english: "Visibility",
            .french: "Visibilité",
            .arabic: "من يمكنه رؤية النشاط"
        ],
        "createActivity.field.visibility.public": [
            .english: "Public - Anyone can join",
            .french: "Public - Tout le monde peut rejoindre",
            .arabic: "عام - يمكن لأي شخص الانضمام"
        ],
        "createActivity.field.visibility.friends": [
            .english: "Friends Only",
            .french: "Amis uniquement",
            .arabic: "الأصدقاء فقط"
        ],
        "createActivity.button.cancel": [
            .english: "Cancel",
            .french: "Annuler",
            .arabic: "إلغاء"
        ],
        "createActivity.button.submit": [
            .english: "Create Activity",
            .french: "Créer l'activité",
            .arabic: "إنشاء النشاط"
        ],
        "createActivity.button.submitting": [
            .english: "Creating...",
            .french: "Création...",
            .arabic: "جارٍ الإنشاء..."
        ],
        "createActivity.error.requiredFields": [
            .english: "Please fill all required fields.",
            .french: "Veuillez remplir tous les champs obligatoires.",
            .arabic: "يرجى ملء جميع الحقول الإلزامية."
        ],
        "createActivity.error.submitFailed": [
            .english: "Failed to create activity.",
            .french: "Échec de la création de l'activité.",
            .arabic: "فشل إنشاء النشاط."
        ],
        "createActivity.error.unknown": [
            .english: "Unknown error",
            .french: "Erreur inconnue",
            .arabic: "خطأ غير معروف"
        ],
        "createActivity.success.title": [
            .english: "Your session is live!",
            .french: "Votre session est en ligne !",
            .arabic: "جلستك أصبحت مباشرة!"
        ],
        "createActivity.success.message": [
            .english: "Your activity has been created. Share the link with friends or wait for others to join.",
            .french: "Votre activité a été créée. Partagez le lien avec vos amis ou attendez que d'autres vous rejoignent.",
            .arabic: "تم إنشاء نشاطك. شارك الرابط مع أصدقائك أو انتظر انضمام الآخرين."
        ],
        "createActivity.success.close": [
            .english: "Close",
            .french: "Fermer",
            .arabic: "إغلاق"
        ],
        "createActivity.success.shareLink": [
            .english: "Share Link",
            .french: "Partager le lien",
            .arabic: "مشاركة الرابط"
        ],
        
        // Create Session (Coach)
        "createSession.nav.title": [
            .english: "Create Session",
            .french: "Créer une session",
            .arabic: "إنشاء جلسة"
        ],
        "createSession.field.sportType": [
            .english: "Sport Type *",
            .french: "Type de sport *",
            .arabic: "نوع الرياضة *"
        ],
        "createSession.field.sportType.placeholder": [
            .english: "Select a sport",
            .french: "Sélectionner un sport",
            .arabic: "اختر رياضة"
        ],
        "createSession.field.title": [
            .english: "Session Title *",
            .french: "Titre de la session *",
            .arabic: "عنوان الجلسة *"
        ],
        "createSession.field.title.placeholder": [
            .english: "e.g., Evening strength session",
            .french: "ex. : Session de renforcement le soir",
            .arabic: "مثال: جلسة قوة مسائية"
        ],
        "createSession.field.price": [
            .english: "Price per Session *",
            .french: "Prix par session *",
            .arabic: "السعر لكل جلسة *"
        ],
        "createSession.field.price.placeholder": [
            .english: "e.g., 20",
            .french: "ex. : 20",
            .arabic: "مثال: 20"
        ],
        "createSession.field.price.currency": [
            .english: "USD",
            .french: "USD",
            .arabic: "دولار"
        ],
        "createSession.field.description": [
            .english: "Description",
            .french: "Description",
            .arabic: "الوصف"
        ],
        "createSession.field.description.placeholder": [
            .english: "Describe the focus of this session...",
            .french: "Décrivez l'objectif de cette session...",
            .arabic: "صف تركيز هذه الجلسة..."
        ],
        "createSession.field.location": [
            .english: "Location *",
            .french: "Lieu *",
            .arabic: "الموقع *"
        ],
        "createSession.field.location.placeholder": [
            .english: "Enter address or venue name",
            .french: "Saisir l'adresse ou le nom du lieu",
            .arabic: "أدخل العنوان أو اسم المكان"
        ],
        "createSession.field.location.mapButton": [
            .english: "Pick from Map",
            .french: "Choisir sur la carte",
            .arabic: "الاختيار من الخريطة"
        ],
        "createSession.field.date": [
            .english: "Date *",
            .french: "Date *",
            .arabic: "التاريخ *"
        ],
        "createSession.field.startSession": [
            .english: "Start Session *",
            .french: "Début de la session *",
            .arabic: "بداية الجلسة *"
        ],
        "createSession.field.endSession": [
            .english: "End Session",
            .french: "Fin de la session",
            .arabic: "نهاية الجلسة"
        ],
        "createSession.field.participants": [
            .english: "Participants",
            .french: "Participants",
            .arabic: "المشاركون"
        ],
        "createSession.field.participants.maxLabel": [
            .english: "Max participants: %d",
            .french: "Participants max. : %d",
            .arabic: "الحد الأقصى للمشاركين: %d"
        ],
        "createSession.field.level": [
            .english: "Level *",
            .french: "Niveau *",
            .arabic: "المستوى *"
        ],
        "createSession.field.level.placeholder": [
            .english: "Select level",
            .french: "Sélectionner un niveau",
            .arabic: "اختر المستوى"
        ],
        "createSession.button.cancel": [
            .english: "Cancel",
            .french: "Annuler",
            .arabic: "إلغاء"
        ],
        "createSession.button.submit": [
            .english: "Create Session",
            .french: "Créer la session",
            .arabic: "إنشاء الجلسة"
        ],
        "createSession.button.submitting": [
            .english: "Creating...",
            .french: "Création...",
            .arabic: "جارٍ الإنشاء..."
        ],
        "createSession.error.invalidPrice": [
            .english: "Please enter a valid price for the session.",
            .french: "Veuillez entrer un prix valide pour la session.",
            .arabic: "يرجى إدخال سعر صحيح للجلسة."
        ],
        "createSession.error.submitFailed": [
            .english: "Failed to create session.",
            .french: "Échec de la création de la session.",
            .arabic: "فشل إنشاء الجلسة."
        ],
        "aiMatchmaker.nav.title": [
            .english: "AI Matchmaker",
            .french: "Matchmaker IA",
            .arabic: "صانع المطابقات الذكي"
        ],
        "aiMatchmaker.input.placeholder": [
            .english: "Ask me anything...",
            .french: "Posez-moi une question...",
            .arabic: "اسألني أي شيء..."
        ],
        "aiMatchmaker.initial.text": [
            .english: "Hi! I'm your AI matchmaker. I can help you find the perfect sport partners or activities. What would you like to do today?",
            .french: "Salut ! Je suis ton matchmaker IA. Je peux t'aider à trouver les meilleurs partenaires de sport ou des activités. Que veux-tu faire aujourd'hui ?",
            .arabic: "مرحبًا! أنا صانع المطابقات الذكي. أستطيع مساعدتك في العثور على أفضل شركاء الرياضة أو الأنشطة. ماذا تريد أن تفعل اليوم؟"
        ],
        "aiMatchmaker.initial.option.running": [
            .english: "Find a running partner",
            .french: "Trouver un partenaire de course",
            .arabic: "البحث عن شريك للجري"
        ],
        "aiMatchmaker.initial.option.groupActivity": [
            .english: "Join a group activity",
            .french: "Rejoindre une activité de groupe",
            .arabic: "الانضمام إلى نشاط جماعي"
        ],
        "aiMatchmaker.initial.option.discoverSports": [
            .english: "Discover new sports",
            .french: "Découvrir de nouveaux sports",
            .arabic: "اكتشاف رياضات جديدة"
        ],
        "aiMatchmaker.error.genericMessage": [
            .english: "Sorry, something went wrong. Please try again.",
            .french: "Désolé, une erreur s'est produite. Veuillez réessayer.",
            .arabic: "عذرًا، حدث خطأ ما. يرجى المحاولة مرة أخرى."
        ],
        "aiMatchmaker.error.option.retry": [
            .english: "Try again",
            .french: "Réessayer",
            .arabic: "إعادة المحاولة"
        ],
        "aiMatchmaker.error.option.groupActivities": [
            .english: "Find group activities",
            .french: "Trouver des activités de groupe",
            .arabic: "البحث عن أنشطة جماعية"
        ],
        "aiMatchmaker.error.option.partnersNearby": [
            .english: "Find partners nearby",
            .french: "Trouver des partenaires à proximité",
            .arabic: "البحث عن شركاء بالقرب منك"
        ],
        "aiMatchmaker.section.suggestedActivities": [
            .english: "Suggested Activities",
            .french: "Activités suggérées",
            .arabic: "أنشطة مقترحة"
        ],
        "aiMatchmaker.section.suggestedPartners": [
            .english: "Suggested Partners",
            .french: "Partenaires suggérés",
            .arabic: "شركاء مقترحون"
        ],
        "aiMatchmaker.section.tryTheseSports": [
            .english: "Try These Sports",
            .french: "Essaie ces sports",
            .arabic: "جرّب هذه الرياضات"
        ],
        "aiMatchmaker.match.scoreFormat": [
            .english: "%d%% match",
            .french: "%d%% de compatibilité",
            .arabic: "%d%% تطابق"
        ],
        "aiMatchmaker.activity.participantsFormat": [
            .english: "%d/%d joined",
            .french: "%d/%d inscrits",
            .arabic: "%d/%d منضمّين"
        ],
        "aiMatchmaker.activity.joinButton": [
            .english: "Join Activity",
            .french: "Rejoindre l'activité",
            .arabic: "الانضمام إلى النشاط"
        ],
        "aiMatchmaker.user.viewProfileButton": [
            .english: "View Profile",
            .french: "Voir le profil",
            .arabic: "عرض الملف الشخصي"
        ],
        "aiMatchmaker.user.connectButton": [
            .english: "Connect",
            .french: "Se connecter",
            .arabic: "تواصل"
        ],
        "aiMatchmaker.sport.tellMeMoreFormat": [
            .english: "Tell me more about %@",
            .french: "Dis-m'en plus sur %@",
            .arabic: "أخبرني المزيد عن %@"
        ],
        "aiMatchmaker.activity.joinConfirmation": [
            .english: "Great! I've added you to the activity. You'll receive a confirmation shortly.",
            .french: "Super ! Je t'ai ajouté à l'activité. Tu recevras une confirmation sous peu.",
            .arabic: "رائع! لقد أضفتك إلى النشاط. ستتلقى تأكيدًا قريبًا."
        ],
        
        // AI Coach
        "coach.title": [
            .english: "AI Coach",
            .french: "Coach IA",
            .arabic: "المدرب الذكي"
        ],
        
        // Common
        "common.cancel": [
            .english: "Cancel",
            .french: "Annuler",
            .arabic: "إلغاء"
        ],
        "common.share": [
            .english: "Share",
            .french: "Partager",
            .arabic: "مشاركة"
        ],
        "common.message": [
            .english: "Message",
            .french: "Message",
            .arabic: "رسالة"
        ],
        "common.ok": [
            .english: "OK",
            .french: "OK",
            .arabic: "حسناً"
        ],
        "common.error": [
            .english: "Error",
            .french: "Erreur",
            .arabic: "خطأ"
        ],
        "common.success": [
            .english: "Success",
            .french: "Succès",
            .arabic: "تم بنجاح"
        ],
        "common.save": [
            .english: "Save",
            .french: "Enregistrer",
            .arabic: "حفظ"
        ],
        "common.back": [
            .english: "Back",
            .french: "Retour",
            .arabic: "رجوع"
        ]
    ]
    
    private init() {
        if let stored = UserDefaults.standard.string(forKey: "app_language"),
           let lang = AppLanguage(rawValue: stored) {
            self.language = lang
        } else {
            self.language = .english
        }
    }
    
    // Update language and persist it
    func setLanguage(_ language: AppLanguage) {
        guard self.language != language else { return }
        self.language = language
        UserDefaults.standard.set(language.rawValue, forKey: "app_language")
    }
    
    // RTL helper for Arabic
    var isRTL: Bool {
        language == .arabic
    }
    
    // Lookup helper used by views / view models
    func localized(_ key: String) -> String {
        translations[key]?[language]
        ?? translations[key]?[.english]
        ?? key
    }
}
