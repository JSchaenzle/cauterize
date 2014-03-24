#define CAUTERIZE_C

#include "cauterize.h"
#include "cauterize_util.h"
#include "cauterize_debug.h"

#include <string.h>

#define S CAUTERIZE_STATUS_T
#define T struct Cauterize

S CauterizeInitAppend(T * m, uint8_t * buffer, uint32_t length)
{
  CA_ASSERT(NULL != m);
  CA_ASSERT(NULL != buffer);

  m->size = length;
  m->used = 0;
  m->pos = 0;
  m->buffer = buffer;

  return CA_OK;
}

S CauterizeInitRead(T * m, uint8_t * buffer, uint32_t used)
{
  CA_ASSERT(NULL != m);
  CA_ASSERT(NULL != buffer);

  m->size = used;
  m->used = used;
  m->pos = 0;
  m->buffer = buffer;

  return CA_OK;
}

S CauterizeAppend(T * m, uint8_t * src, uint32_t length)
{
  CA_ASSERT(NULL != m);
  CA_ASSERT(NULL != src);

  uint32_t needed = m->used + length;

  if (needed > m->size)
    return CA_ERR_NOT_ENOUGH_SPACE;

  uint8_t * dest = &m->buffer[m->used];
  memcpy(dest, src, length);
  m->used += length;

  return CA_OK;
}

S CauterizeRead(T * m, uint8_t * dst, uint32_t length)
{
  CA_ASSERT(NULL != m);
  CA_ASSERT(NULL != dst);
  CA_ASSERT(m->used >= m->pos);

  uint32_t available = m->used - m->pos;

  if (length > available)
    return CA_ERR_NOT_ENOUGH_DATA;

  uint8_t * src = &m->buffer[m->pos];
  memcpy(dst, src, length);
  m->pos += length;

  return CA_OK;
}

#define CHECKSUM_SIZE 4

S CauterizeStartChecksum(T * m, uint32_t * start)
{
  CA_ASSERT(NULL != m);
  CA_ASSERT(NULL != start);

  if (m->size - m->used >= CHECKSUM_SIZE) {
    m->used += CHECKSUM_SIZE;
    *start = m->used;
    return CA_OK;
  }
  else {
    *start = 0;
    return CA_ERR_NOT_ENOUGH_SPACE;
  }
}

S CauterizeWriteChecksum(T * m, uint32_t start)
{
  CA_ASSERT(NULL != m);
  CA_ASSERT(start >= CHECKSUM_SIZE);

  S err;
  T checksum_pos;
  CauterizeInitAppend(&checksum_pos, m->buffer + start - CHECKSUM_SIZE, CHECKSUM_SIZE);
  uint16_t length = m->used - start;
  uint16_t checksum = CauterizeChecksum(m->buffer + start, m->buffer + m->used);
  if (CA_OK != (err = CauterizeAppend(&checksum_pos, (uint8_t *)&length, sizeof(length)))) { return err; }
  if (CA_OK != (err = CauterizeAppend(&checksum_pos, (uint8_t *)&checksum, sizeof(checksum)))) { return err; }
  return CA_OK;
}

S CauterizeVerifyChecksum(T * m)
{
  CA_ASSERT(NULL != m);

  S err;
  uint16_t length;
  uint16_t checksum;
  if (CA_OK != (err = CauterizeRead(m, (uint8_t *)&length, sizeof(length)))) { return err; }
  if (CA_OK != (err = CauterizeRead(m, (uint8_t *)&checksum, sizeof(checksum)))) { return err; }
  if (m->used - m->pos < length) { return CA_ERR_NOT_ENOUGH_DATA; }
  uint16_t verify = CauterizeChecksum(m->buffer + m->pos, m->buffer + m->pos + length);
  if (verify != checksum) { return CA_ERR_INVALID_CHECKSUM; }
  return CA_OK;
}

uint16_t CauterizeChecksum(uint8_t * start, uint8_t * end)
{
  CA_ASSERT(NULL != start);
  CA_ASSERT(start <= end);

  uint32_t sum = 0;
  while (start < end) {
    uint32_t lo = *start++;
    uint32_t hi = (start < end) ? *start++ : 0;
    sum += (hi << 8) | lo;
  }
  while (sum >> 16) {
    sum = (sum & 0xffff) + (sum >> 16);
  }
  return ~sum;
}

#undef S
#undef T
#undef CAUTERIZE_C
