# Go

## Style Guide

- `gofmt` 자동 포맷팅 필수
- `golint`, `go vet` 통과
- Effective Go 가이드라인 준수

## Naming

```go
// 패키지명: 소문자, 단일 단어
package user

// 공개 (exported): PascalCase
type User struct {}
func NewUser() *User {}

// 비공개: camelCase
type userData struct {}
func validateEmail(email string) bool {}

// 인터페이스: -er 접미사 (단일 메서드)
type Reader interface {
    Read(p []byte) (n int, err error)
}

// Getter: Get 접두사 생략
func (u *User) Name() string { return u.name }

// Setter: Set 접두사 사용
func (u *User) SetName(name string) { u.name = name }
```

## Error Handling

```go
// 에러는 마지막 반환값
func FindUser(id string) (*User, error) {
    user, err := db.Query(id)
    if err != nil {
        return nil, fmt.Errorf("finding user %s: %w", id, err)
    }
    return user, nil
}

// 커스텀 에러 타입
type NotFoundError struct {
    Resource string
    ID       string
}

func (e *NotFoundError) Error() string {
    return fmt.Sprintf("%s not found: %s", e.Resource, e.ID)
}

// 에러 체크
if errors.Is(err, sql.ErrNoRows) {
    return nil, &NotFoundError{Resource: "user", ID: id}
}

// 에러 타입 확인
var notFound *NotFoundError
if errors.As(err, &notFound) {
    // handle not found
}
```

## Structs & Interfaces

```go
// 구조체
type User struct {
    ID        string    `json:"id"`
    Name      string    `json:"name"`
    CreatedAt time.Time `json:"created_at"`
}

// 생성자 함수
func NewUser(name string) *User {
    return &User{
        ID:        uuid.New().String(),
        Name:      name,
        CreatedAt: time.Now(),
    }
}

// 인터페이스는 사용하는 쪽에서 정의
type UserStore interface {
    Find(id string) (*User, error)
    Save(user *User) error
}

// 구현
type PostgresUserStore struct {
    db *sql.DB
}

func (s *PostgresUserStore) Find(id string) (*User, error) {
    // ...
}
```

## Concurrency

```go
// Goroutine + Channel
func processItems(items []Item) <-chan Result {
    results := make(chan Result)
    go func() {
        defer close(results)
        for _, item := range items {
            results <- process(item)
        }
    }()
    return results
}

// Worker Pool
func workerPool(jobs <-chan Job, results chan<- Result, workers int) {
    var wg sync.WaitGroup
    for i := 0; i < workers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for job := range jobs {
                results <- process(job)
            }
        }()
    }
    wg.Wait()
    close(results)
}

// Context로 취소
func fetchWithTimeout(ctx context.Context, url string) (*Response, error) {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    
    req, _ := http.NewRequestWithContext(ctx, "GET", url, nil)
    return http.DefaultClient.Do(req)
}
```

## Project Structure

```
myapp/
├── cmd/
│   └── myapp/
│       └── main.go
├── internal/
│   ├── user/
│   │   ├── handler.go
│   │   ├── service.go
│   │   └── repository.go
│   └── config/
├── pkg/
│   └── utils/
├── go.mod
├── go.sum
└── Makefile
```
