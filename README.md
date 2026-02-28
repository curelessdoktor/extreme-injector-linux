<<<<<<< HEAD
# Extreme Injector v1

Linux .so injector — inject shared libraries into running processes. Coded for fun.

GUI in the style of the classic Extreme Injector: pick a process, add `.so` files, click Inject.

## Quick start

```bash
cd extreme_injector
pip install -r requirements.txt
cd injector && make && cd ..
python main.py
```

**Requirements:** Python 3.10+, PyQt6, gcc. For injection you may need:
`echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope`

See [extreme_injector/README.md](extreme_injector/README.md) for full setup and usage.

## License

See [LICENSE](LICENSE).
=======
# extreme-injector-linux
extreme injector from windows but remade in linux
>>>>>>> c45a8583fd871c089f599c5f4cf84654e1f2ca8e
