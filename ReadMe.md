# Asymptome
CLI tracker to prioritize your limited time by ELO ranking media.

## Initial Ideas
- [x] Mark books read/unread/in-progress.
- [x] Show top 10 / bottom 10. Show only in-progress or unread.
- [ ] Rank only in-progress or unread.
- [x] Track books by title, author, and series. Default is to recognize "by" or "(series)" and automatically sort into relevant fields.
  - [x] But also almost nothing is actually *needed*.
- [x] Store pages as an option,
  - [x] allow a weighted priority based on remaining percentage or whatever.
- [x] Store items as an array instead of object, because that makes the JSON output more consistent -> smaller JSON commit differences.
      - [ ] I am not sure this actually helps much when EACH ITEM is still an
            object. I need to make the JSON export sort its keys.
- [ ] Re-implement ELO ranking.
- [ ] Display filter/sort options to output lists. (Focus only on top 10 items?)

## Contributions

This repo is hosted at https://gitea.tangentfox.com/tangent/Asymptome and
force-pushed to https://github.com/TangentFoxy/Asymptome when commits are made.
I accept pull requests and issues, but management of the code is handled there.

Licensing? I don't care. Do whatever you want. IP rights are stupid.

## Ideas
- [ ] When importing, allow user to make a choice when duplicates are detected
      instead of rejecting them automatically.
- [ ] When importing, a duplicate should still be checked for missing data, and
      merge rather than ignore.

## Book Data Structure
```json
{
  "title": "Title",
  "author": "Author",
  "series": "Series",
  "genre": "Fiction",
  "pages": 100,
  "priority": 0,
  "progress": 0.5,
  "hidden": true
}
```

- `title`, `author`, `series`, `pages`, `genre`, and `hidden` are optional.
- At least one of `title`, `author`, `series`, or `genre` must be defined.
- `priority` is the ELO ranking, initializing to `0`.
- `progress` represents read/unread/in-progress status. `0` is unread, `1` is
  read, and anything in-between in a percentage of progress.
- `hidden` is undefined or `true` to hide a book from ALL of the interface
  without deleting its data.

Despite the script supporting otherwise, I highly recommend only using this for
*specific book titles*. In my experience, using entries representing multiple
books makes it more difficult to prioritize and use.

## Why "Asymptome" ?
A combination of asymptote - because you will die before you finish your reading
list, always getting closer but never arriving - and tome.

It's also a-symptom of my neuroses. :D
