# Build the inject binary for x86_64 (required for .so injection)
# Uses ptrace; may require: echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope

CC = gcc
CFLAGS = -Wall -O2 -D_GNU_SOURCE
CFLAGS32 = -Wall -O2 -D_GNU_SOURCE -m32
LDFLAGS = -ldl
LDFLAGS32 = -m32 -ldl

SRCS = inject-x86_64.c ptrace.c utils.c
SRCS32 = inject-x86.c ptrace.c utils.c
TARGET = inject
TARGET32 = inject32

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRCS) $(LDFLAGS)

$(TARGET32): $(SRCS32)
	$(CC) $(CFLAGS32) -o $(TARGET32) $(SRCS32) $(LDFLAGS32)

clean:
	rm -f $(TARGET) $(TARGET32)

.PHONY: all clean
