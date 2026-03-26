#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# سكريبت رفع مشروع سينمانا على GitHub من Termux
# الاستخدام: bash setup_github.sh
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "  ╔══════════════════════════════════╗"
echo "  ║     سينمانا — رفع على GitHub    ║"
echo "  ╚══════════════════════════════════╝"
echo -e "${NC}"

# ─── التحقق من git ────────────────────────────────────────────
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}تثبيت git...${NC}"
    pkg install -y git
fi

# ─── معلومات المستخدم ─────────────────────────────────────────
echo -e "${CYAN}أدخل معلومات GitHub:${NC}"
read -p "اسم المستخدم (username): " GH_USER
read -p "اسم الريبو الجديد (مثل: cinemana-app): " REPO_NAME
read -p "GitHub Token (ghp_...): " GH_TOKEN
read -p "بريدك الإلكتروني: " GH_EMAIL

echo ""
echo -e "${YELLOW}⚙️  إعداد git...${NC}"
git config --global user.name "$GH_USER"
git config --global user.email "$GH_EMAIL"

# ─── إنشاء الريبو عبر API ─────────────────────────────────────
echo -e "${YELLOW}🌐 إنشاء ريبو على GitHub...${NC}"
RESPONSE=$(curl -s -o /tmp/gh_response.json -w "%{http_code}" \
  -X POST \
  -H "Authorization: token $GH_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/user/repos \
  -d "{
    \"name\": \"$REPO_NAME\",
    \"description\": \"تطبيق سينمانا - أفلام ومسلسلات\",
    \"private\": false,
    \"auto_init\": false
  }")

if [ "$RESPONSE" = "201" ]; then
    echo -e "${GREEN}✅ تم إنشاء الريبو بنجاح${NC}"
elif [ "$RESPONSE" = "422" ]; then
    echo -e "${YELLOW}⚠️  الريبو موجود مسبقاً، سيتم استخدامه${NC}"
else
    echo -e "${RED}❌ خطأ في إنشاء الريبو (HTTP $RESPONSE)${NC}"
    cat /tmp/gh_response.json
    exit 1
fi

REMOTE_URL="https://$GH_TOKEN@github.com/$GH_USER/$REPO_NAME.git"

# ─── تهيئة git وعمل push ──────────────────────────────────────
echo -e "${YELLOW}📦 تهيئة git...${NC}"

cd "$(dirname "$0")"

git init 2>/dev/null || true
git add .
git commit -m "🎬 initial commit: سينمانا Flutter app" 2>/dev/null || \
  git commit --allow-empty -m "🎬 initial commit: سينمانا Flutter app"

git branch -M main
git remote remove origin 2>/dev/null || true
git remote add origin "$REMOTE_URL"

echo -e "${YELLOW}🚀 رفع الكود...${NC}"
git push -u origin main --force

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║             ✅ تم الرفع بنجاح!             ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║ 🌐 الريبو: https://github.com/$GH_USER/$REPO_NAME${NC}"
echo -e "${GREEN}║ ⚙️  Actions: https://github.com/$GH_USER/$REPO_NAME/actions${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📌 الخطوات التالية:${NC}"
echo "1. افتح: https://github.com/$GH_USER/$REPO_NAME/actions"
echo "2. ستجد الـ Build يعمل تلقائياً الآن"
echo "3. بعد الانتهاء حمّل APK من: Actions → أحدث run → Artifacts"
echo ""
echo -e "${CYAN}📌 لإضافة Keystore للتوقيع (اختياري):${NC}"
echo "   Settings → Secrets → New secret:"
echo "   KEY_STORE       = \$(base64 -w 0 keystore.jks)"
echo "   KEY_STORE_PASSWORD = كلمة مرور الـ keystore"
echo "   KEY_ALIAS       = اسم الـ alias"
echo "   KEY_PASSWORD    = كلمة مرور الـ key"
