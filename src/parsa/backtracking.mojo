from parsa.grammar import Token, Tokenizer


struct BacktrackingTokenizer[TK: Tokenizer](
    Copyable, Iterable, Iterator, Movable
):
    alias Element = TK.Element

    alias IteratorType[
        iterable_mut: Bool, //, iterable_origin: Origin[iterable_mut]
    ]: Iterator = Self

    var tokenizer: TK
    var tokens: List[TK.Element]
    var next_index: Int
    var is_recording: Bool

    fn __init__(out self, var tokenizer: TK):
        self.tokenizer = tokenizer^
        self.tokens = {}
        self.next_index = {}
        self.is_recording = {}

    @always_inline
    fn start(mut self, token: TK.Element) -> Int:
        self.is_recording = True
        if len(self.tokens) == 0:
            self.tokens.append(token.copy())
            self.next_index = 1
            return 0
        return self.next_index - 1

    @always_inline
    fn reset(mut self, token_index: Int):
        self.next_index = token_index

    @always_inline
    fn stop(mut self):
        self.is_recording = False

    fn __has_next__(self) -> Bool:
        return (len(self.tokens) == 0 and self.tokenizer.__has_next__()) or (
            len(self.tokens) > 0
            and (
                self.next_index < len(self.tokens)
                or self.tokenizer.__has_next__()
            )
        )

    fn __next__(mut self) -> Self.Element:
        if len(self.tokens) == 0:
            return self.tokenizer.__next__()

        # self.tokens have values.
        if self.next_index >= len(self.tokens):  # use tokenizer
            var token = self.tokenizer.__next__()
            if self.is_recording:
                self.next_index += 1
                self.tokens.append(token.copy())
            else:
                self.next_index = 0
                self.tokens.clear()
            return token^

        # Token can give out what it have based on the index value
        self.next_index += 1
        return self.tokens[self.next_index].copy()

    fn __iter__(ref self) -> Self.IteratorType[__origin_of(self)]:
        return self.copy()
