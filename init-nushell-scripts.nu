#!/usr/bin/env nu

# nushell/scripts sparse checkout 초기화 스크립트
# dotfiles를 새로 clone한 환경에서 nushell/scripts를 설정

const NU_SCRIPTS_REPO = "https://github.com/nushell/nu_scripts.git"

# Sparse checkout 패턴 설정
const SPARSE_PATTERNS = [
    "aliases/docker/",
    "aliases/git/", 
    "custom-completions/aws/",
    "custom-completions/curl/",
    "custom-completions/docker/",
    "custom-completions/gh/",
    "custom-completions/git/",
    "custom-completions/gradlew/",
    "custom-completions/npm/",
    "custom-completions/rustup/",
    "custom-completions/yarn/",
    "custom-completions/zoxide/",
    "LICENSE",
    "README.md",
    "toolkit.nu",
    "typos.toml"
]

# 메인 초기화 함수
def main [
    command?: string  # 선택적 명령어: update, status, help
] {
    match $command {
        "update" => { update }
        "status" => { status }
        "help" => { help }
        null => { init_scripts }
        _ => {
            print $"❌ 알 수 없는 명령어: ($command)"
            help
        }
    }
}

def init_scripts [] {
    let scripts_dir = ($env.PWD | path join "nushell" "scripts")
    
    print $"🔧 nushell/scripts 초기화 중... ($scripts_dir)"
    
    # scripts 디렉토리 생성 (존재하지 않을 경우)
    if not ($scripts_dir | path exists) {
        print "📁 scripts 디렉토리 생성 중..."
        mkdir $scripts_dir
    }
    
    cd $scripts_dir
    
    # 기존 .git이 있으면 제거 후 재설정
    if (".git" | path exists) {
        print "🗑️  기존 .git 디렉토리 제거 중..."
        rm -rf .git
    }
    
    # Git 저장소 초기화
    print "🚀 Git 저장소 초기화 중..."
    git init
    git remote add origin $NU_SCRIPTS_REPO
    
    # Sparse checkout 활성화
    print "⚙️  Sparse checkout 설정 중..."
    git config core.sparseCheckout true
    
    # .git/info 디렉토리가 없으면 생성
    let git_info_dir = ".git/info"
    if not ($git_info_dir | path exists) {
        mkdir $git_info_dir
    }
    
    # Sparse checkout 패턴 파일 생성
    let sparse_checkout_file = ($git_info_dir | path join "sparse-checkout")
    $SPARSE_PATTERNS | str join "\n" | save $sparse_checkout_file
    
    print "📥 원격 저장소에서 데이터 가져오는 중..."
    git fetch origin main
    
    print "📋 메인 브랜치로 체크아웃 중..."
    git checkout -b main origin/main
    
    # Sparse checkout 적용
    print "🎯 Sparse checkout 적용 중..."
    git sparse-checkout reapply
    
    print "✅ 초기화 완료!"
    print ""
    print "📊 설정된 파일/디렉토리:"
    ls | get name | each { |file| print $"  - ($file)" }
    
    print ""
    print "🔄 향후 업데이트 방법:"
    print "  cd nushell/scripts && git pull origin main"
}

# 업데이트 함수 (초기화 이후 사용)
export def update [] {
    let scripts_dir = ($env.PWD | path join "nushell" "scripts")
    
    if not ($scripts_dir | path exists) {
        print "❌ scripts 디렉토리가 존재하지 않습니다."
        print "   초기화를 먼저 실행하세요: nu init-nushell-scripts.nu"
        return
    }
    
    cd $scripts_dir
    
    if not (".git" | path exists) {
        print "❌ Git 저장소가 초기화되지 않았습니다."
        print "   초기화를 먼저 실행하세요: nu init-nushell-scripts.nu"
        return
    }
    
    print "🔄 nushell/scripts 업데이트 중..."
    
    git fetch origin main
    git reset --hard origin/main
    git sparse-checkout reapply
    
    print "✅ 업데이트 완료!"
}

# 상태 확인 함수
export def status [] {
    let scripts_dir = ($env.PWD | path join "nushell" "scripts")
    
    if not ($scripts_dir | path exists) {
        print "❌ scripts 디렉토리가 존재하지 않습니다."
        return
    }
    
    cd $scripts_dir
    
    if not (".git" | path exists) {
        print "❌ Git 저장소가 초기화되지 않았습니다."
        return
    }
    
    print "📊 nushell/scripts 상태:"
    git status --porcelain
    
    print "\n🔍 Sparse checkout 패턴:"
    open .git/info/sparse-checkout
}

# 도움말
export def help [] {
    print "nushell/scripts 관리 명령어:"
    print ""
    print "  nu init-nushell-scripts.nu        - 초기화 (최초 1회)"
    print "  nu init-nushell-scripts.nu update - 업스트림 업데이트" 
    print "  nu init-nushell-scripts.nu status - 상태 확인"
    print "  nu init-nushell-scripts.nu help   - 도움말"
    print ""
    print "💡 dotfiles를 새로 clone한 후 반드시 초기화를 실행하세요!"
}