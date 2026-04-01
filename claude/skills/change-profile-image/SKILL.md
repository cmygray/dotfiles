---
name: change-profile-image
description: 기관 교표(프로필 이미지) 변경. "교표 변경", "기관 로고", "프로필 이미지 변경" 등의 요청에 반응.
allowed-tools: Bash(python3 *), Bash(aws-vault exec * -- dy *), Bash(open *), Bash(file *), Bash(stat *)
---

# 기관 교표(프로필 이미지) 변경

기관의 교표/로고 이미지를 미디어 서비스에 업로드하고 DynamoDB 레코드를 업데이트합니다.

## 필요한 정보

사용자에게 다음 정보를 확인:

- **기관 ID** (숫자)
- **이미지 파일 경로** (로컬 파일)
- **인증 토큰** — [클래스팅 어드민](https://classting-admin.classting.com/) 로그인 후 Bearer 토큰

## 워크플로우

### Step 1: 이미지 파일 확인

```bash
file <image_path>
stat -f "%z" <image_path>
```

파일 형식(png/jpg)과 크기(bytes)를 확인한다.

### Step 2: 미디어 서비스에 이미지 생성 요청

```bash
python3 << 'EOF'
import requests, json

resp = requests.post(
    "https://apis.classting.com/media-service/admin/images",
    headers={
        "Authorization": "Bearer <TOKEN>",
        "Content-Type": "application/json; charset=utf-8",
    },
    json={
        "categoryType": "Organization",
        "categoryId": "<ORG_ID>",
        "originalFileName": "<FILENAME>",
        "contentType": "image/png",  # or image/jpeg
        "totalSize": <FILE_SIZE>,
    },
)
print(json.dumps(resp.json(), indent=2))
EOF
```

응답에서 `presignedPost`(url, fields)와 `urls.original`을 추출한다.

### Step 3: S3 Presigned POST로 이미지 업로드

**반드시 Python requests를 사용한다** (curl은 content-disposition 이스케이프 문제 발생).

```bash
python3 << 'EOF'
import requests

url = "<presignedPost.url>"
fields = {
    # presignedPost.fields의 모든 키-값을 그대로 사용
    "Key": "...",
    "bucket": "...",
    # ... (모든 fields)
    "content-disposition": 'attachment; filename="<FILENAME>"; filename*=UTF-8\'\'<FILENAME>',
    "x-amz-storage-class": "INTELLIGENT_TIERING",
    "acl": "public-read",
    "Content-Type": "image/png",  # or image/jpeg
}

with open("<IMAGE_PATH>", "rb") as f:
    files = {"file": ("<FILENAME>", f, "image/png")}
    resp = requests.post(url, data=fields, files=files)

print(f"Status: {resp.status_code}")
if resp.status_code >= 300:
    print(resp.text)
EOF
```

**성공 응답: 204 No Content**

### Step 4: DynamoDB 기관 레코드 업데이트

먼저 현재 레코드를 조회하여 기관명과 현재 profileImage를 확인:

```bash
aws-vault exec classting-prod -- dy get -t organization-service-prod 'Organization#<ORG_ID>' 'Organization#<ORG_ID>'
```

업데이트 명령어를 **사용자에게 보여주고 확인받은 후** 실행:

```bash
aws-vault exec classting-prod -- dy upd -t organization-service-prod \
  'Organization#<ORG_ID>' 'Organization#<ORG_ID>' \
  --set 'profileImage = "<NEW_IMAGE_URL>"'
```

### Step 5: 검증

업로드된 이미지를 브라우저에서 확인:

```bash
open "<NEW_IMAGE_URL>"
```

## 주의사항

- S3 업로드 시 **curl 사용 금지** — content-disposition 이스케이프 문제로 403 발생
- DynamoDB 업데이트 전 **반드시 사용자 확인** 필요 (prod 환경 쓰기)
- presignedPost.fields의 모든 필드를 빠짐없이 포함해야 함
